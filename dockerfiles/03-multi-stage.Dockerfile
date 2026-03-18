# Example 3: Multi-Stage Build
# ==============================
# Pros:
#   - Small final image (~15MB vs ~800MB)
#   - No build tools in production
#   - Better security (minimal attack surface)
#   - Layer caching optimization
# Cons:
#   - Slightly more complex
#   - Need to understand multi-stage builds
#
# Key Improvements:
#   - Separate build and runtime stages
#   - Only the compiled binary goes to final image
#   - Uses minimal Alpine base for runtime

# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /build

# Copy dependency files first
COPY app/go.mod app/go.sum ./

# Download dependencies (cached layer)
RUN go mod download

# Copy source code
COPY app/ .

# Build static binary
RUN CGO_ENABLED=0 go build -o grocery-app .

# Runtime stage
FROM alpine:latest

WORKDIR /app

# Copy only the binary from builder
COPY --from=builder /build/grocery-app .

# Expose port
EXPOSE 8080

# Run the application
CMD ["./grocery-app"]

