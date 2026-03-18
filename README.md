# Grocery List API

A simple Go server for managing grocery lists with MySQL storage and Prometheus metrics.

## Prerequisites

- Docker
- Go 1.21+

## Quick Start

### Step 1: Start MySQL Database

Run MySQL in a Docker container:

```bash
docker run -d \
  --name grocery-mysql \
  -e MYSQL_ROOT_PASSWORD=password \
  -e MYSQL_DATABASE=groceries \
  -p 3306:3306 \
  mysql:8.0
```

Wait a few seconds for MySQL to initialize, then verify it's running:

```bash
docker ps | grep grocery-mysql
```

### Step 2: Create Database Schema

**Option A: Using the schema.sql file**

```bash
docker exec -i grocery-mysql mysql -uroot -ppassword groceries < schema.sql
```

**Option B: Manually create the table**

Connect to MySQL:
```bash
docker exec -it grocery-mysql mysql -uroot -ppassword groceries
```

Then run this SQL:
```sql
CREATE TABLE grocery_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    item_name VARCHAR(255) NOT NULL,
    quantity INT DEFAULT 1,
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_username (username)
);
```

Exit MySQL:
```sql
exit;
```

### Step 3: Run the Application

#### Option A: Run with Go (Development)

```bash
cd app
go run main.go
```

#### Option B: Build and Run Binary

```bash
cd app
go build -o grocery-app .
./grocery-app
```

#### Option C: Run with Docker

Build the Docker image:
```bash
docker build -t grocery-app .
```

Run the container (linking to MySQL):
```bash
docker run -d \
  --name grocery-app \
  --link grocery-mysql:mysql \
  -e DB_HOST=mysql \
  -e DB_PORT=3306 \
  -e DB_USER=root \
  -e DB_PASSWORD=password \
  -e DB_NAME=groceries \
  -p 8080:8080 \
  grocery-app
```

### Step 4: Test the Application

The application will be available at:
- API: http://localhost:8080
- Health: http://localhost:8080/health
- Metrics: http://localhost:8080/metrics

## API Documentation

Full OpenAPI 3.0 specification is available in [`openapi.yaml`](./openapi.yaml).

You can view it using:
- [Swagger Editor](https://editor.swagger.io/) - paste the content
- [Swagger UI](https://petstore.swagger.io/) - load the file
- VS Code with OpenAPI extensions

## API Endpoints

### 1. Health Check

Check if the service and database are healthy.

**Request:**
```bash
curl http://localhost:8080/health
```

**Response:**
```json
{
  "status": "healthy"
}
```

### 2. Create Grocery List (POST)

Create a new grocery list for a user.

**Request:**
```bash
curl -X POST http://localhost:8080/groceries \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john",
    "items": ["milk", "bread", "eggs", "butter"]
  }'
```

**Response:**
```json
{
  "message": "Grocery list created successfully",
  "username": "john",
  "items_added": 4
}
```

### 3. Get Grocery Lists (GET)

Retrieve all grocery items for a specific user.

**Request:**
```bash
curl "http://localhost:8080/groceries?username=john"
```

**Response:**
```json
{
  "username": "john",
  "count": 4,
  "items": [
    {
      "id": 4,
      "username": "john",
      "item_name": "butter",
      "quantity": 1,
      "created": "2026-03-16T10:30:00Z"
    },
    {
      "id": 3,
      "username": "john",
      "item_name": "eggs",
      "quantity": 1,
      "created": "2026-03-16T10:30:00Z"
    },
    {
      "id": 2,
      "username": "john",
      "item_name": "bread",
      "quantity": 1,
      "created": "2026-03-16T10:30:00Z"
    },
    {
      "id": 1,
      "username": "john",
      "item_name": "milk",
      "quantity": 1,
      "created": "2026-03-16T10:30:00Z"
    }
  ]
}
```

### 4. Prometheus Metrics

View application metrics.

**Request:**
```bash
curl http://localhost:8080/metrics
```

**Available Metrics:**
- `http_requests_total` - Total number of HTTP requests (labeled by method, endpoint, status)
- `http_request_duration_seconds` - Duration of HTTP requests
- `grocery_items_total` - Total number of grocery items created
- `grocery_lists_total` - Total number of grocery lists created

## Example Usage

```bash
# Create a grocery list for user "alice"
curl -X POST http://localhost:8080/groceries \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "items": ["apples", "oranges", "bananas"]
  }'

# Create another list for user "bob"
curl -X POST http://localhost:8080/groceries \
  -H "Content-Type: application/json" \
  -d '{
    "username": "bob",
    "items": ["chicken", "rice", "vegetables"]
  }'

# Get alice's grocery list
curl "http://localhost:8080/groceries?username=alice"

# Get bob's grocery list
curl "http://localhost:8080/groceries?username=bob"

# Check health
curl http://localhost:8080/health

# View metrics
curl http://localhost:8080/metrics
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `localhost` | MySQL host |
| `DB_PORT` | `3306` | MySQL port |
| `DB_USER` | `root` | MySQL user |
| `DB_PASSWORD` | `password` | MySQL password |
| `DB_NAME` | `groceries` | MySQL database name |
| `PORT` | `8080` | Application port |

## Stopping the Application

Stop the Go application (Ctrl+C if running in foreground, or if running as Docker container):

```bash
docker stop grocery-app
docker rm grocery-app
```

Stop and remove MySQL:
```bash
docker stop grocery-mysql
docker rm grocery-mysql
```

To remove MySQL data volume:
```bash
docker volume ls  # Find the volume name
docker volume rm <volume-name>
```

