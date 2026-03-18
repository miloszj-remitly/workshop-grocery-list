package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// GroceryItem represents a single grocery item
type GroceryItem struct {
	ID       int    `json:"id"`
	Username string `json:"username"`
	ItemName string `json:"item_name"`
	Quantity int    `json:"quantity"`
	Created  string `json:"created"`
}

// GroceryListRequest represents the request body for creating a grocery list
type GroceryListRequest struct {
	Username string   `json:"username"`
	Items    []string `json:"items"`
}

var (
	db *sql.DB

	// Prometheus metrics
	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	httpRequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "Duration of HTTP requests in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint"},
	)

	groceryItemsTotal = prometheus.NewCounter(
		prometheus.CounterOpts{
			Name: "grocery_items_total",
			Help: "Total number of grocery items created",
		},
	)

	groceryListsTotal = prometheus.NewCounter(
		prometheus.CounterOpts{
			Name: "grocery_lists_total",
			Help: "Total number of grocery lists created",
		},
	)
)

func init() {
	// Register Prometheus metrics
	prometheus.MustRegister(httpRequestsTotal)
	prometheus.MustRegister(httpRequestDuration)
	prometheus.MustRegister(groceryItemsTotal)
	prometheus.MustRegister(groceryListsTotal)
}

func main() {
	// Initialize database connection
	var err error
	dbHost := getEnv("DB_HOST", "localhost")
	dbPort := getEnv("DB_PORT", "3306")
	dbUser := getEnv("DB_USER", "root")
	dbPassword := getEnv("DB_PASSWORD", "password")
	dbName := getEnv("DB_NAME", "groceries")

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true",
		dbUser, dbPassword, dbHost, dbPort, dbName)

	// Retry connection logic
	for i := 0; i < 10; i++ {
		db, err = sql.Open("mysql", dsn)
		if err != nil {
			log.Printf("Failed to open database: %v, retrying...", err)
			time.Sleep(2 * time.Second)
			continue
		}

		err = db.Ping()
		if err != nil {
			log.Printf("Failed to ping database: %v, retrying...", err)
			time.Sleep(2 * time.Second)
			continue
		}

		log.Println("Successfully connected to database")
		break
	}

	if err != nil {
		log.Fatalf("Could not connect to database after retries: %v", err)
	}

	defer db.Close()

	log.Println("Successfully connected to database")

	// Setup routes
	http.HandleFunc("/health", metricsMiddleware(healthHandler))
	http.HandleFunc("/groceries", metricsMiddleware(groceriesHandler))
	http.Handle("/metrics", promhttp.Handler())

	port := getEnv("PORT", "8080")
	log.Printf("Server starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

// metricsMiddleware wraps handlers to collect metrics
func metricsMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// Create a custom response writer to capture status code
		rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		next(rw, r)

		duration := time.Since(start).Seconds()
		httpRequestDuration.WithLabelValues(r.Method, r.URL.Path).Observe(duration)
		httpRequestsTotal.WithLabelValues(r.Method, r.URL.Path, fmt.Sprintf("%d", rw.statusCode)).Inc()
	}
}

// responseWriter wraps http.ResponseWriter to capture status code
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// healthHandler handles health check requests
func healthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Check database connection
	err := db.Ping()
	if err != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		json.NewEncoder(w).Encode(map[string]string{
			"status": "unhealthy",
			"error":  err.Error(),
		})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "healthy",
	})
}

// groceriesHandler handles both GET and POST requests for groceries
func groceriesHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case http.MethodPost:
		handleCreateGroceryList(w, r)
	case http.MethodGet:
		handleGetGroceryLists(w, r)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// handleCreateGroceryList creates a new grocery list for a user
func handleCreateGroceryList(w http.ResponseWriter, r *http.Request) {
	var req GroceryListRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Username == "" {
		http.Error(w, "Username is required", http.StatusBadRequest)
		return
	}

	if len(req.Items) == 0 {
		http.Error(w, "At least one item is required", http.StatusBadRequest)
		return
	}

	// Insert items into database
	stmt, err := db.Prepare("INSERT INTO grocery_items (username, item_name, quantity) VALUES (?, ?, ?)")
	if err != nil {
		log.Printf("Failed to prepare statement: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	defer stmt.Close()

	itemCount := 0
	for _, item := range req.Items {
		if item == "" {
			continue
		}
		_, err = stmt.Exec(req.Username, item, 1)
		if err != nil {
			log.Printf("Failed to insert item: %v", err)
			http.Error(w, "Failed to save items", http.StatusInternalServerError)
			return
		}
		itemCount++
		groceryItemsTotal.Inc()
	}

	if itemCount > 0 {
		groceryListsTotal.Inc()
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"message":     "Grocery list created successfully",
		"username":    req.Username,
		"items_added": itemCount,
	})
}

// handleGetGroceryLists retrieves grocery lists for a user
func handleGetGroceryLists(w http.ResponseWriter, r *http.Request) {
	username := r.URL.Query().Get("username")
	if username == "" {
		http.Error(w, "Username query parameter is required", http.StatusBadRequest)
		return
	}

	rows, err := db.Query("SELECT id, username, item_name, quantity, created FROM grocery_items WHERE username = ? ORDER BY created DESC", username)
	if err != nil {
		log.Printf("Failed to query items: %v", err)
		http.Error(w, "Failed to retrieve items", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var items []GroceryItem
	for rows.Next() {
		var item GroceryItem
		var created time.Time
		err := rows.Scan(&item.ID, &item.Username, &item.ItemName, &item.Quantity, &created)
		if err != nil {
			log.Printf("Failed to scan row: %v", err)
			continue
		}
		item.Created = created.Format(time.RFC3339)
		items = append(items, item)
	}

	if items == nil {
		items = []GroceryItem{}
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"username": username,
		"items":    items,
		"count":    len(items),
	})
}

// getEnv gets an environment variable or returns a default value
func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

