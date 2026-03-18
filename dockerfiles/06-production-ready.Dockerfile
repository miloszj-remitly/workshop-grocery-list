# Example 6: Production-Ready with Best Practices
# =================================================
# Pros:
#   - Small image size (~15MB)
#   - Security hardening (non-root user)
#   - Health checks included
#   - Proper CA certificates
#   - Build optimizations
#   - Good balance of security and debuggability
# Cons:
#   - More complex
#   - Requires understanding of security best practices
#
# Key Improvements:
#   - Non-root user for security
#   - Health check configuration
#   - CA certificates for HTTPS
#   - Optimized build flags
#   - Metadata labels

# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /build

# Install CA certificates in builder
RUN apk --no-cache add ca-certificates

# Copy dependency files first
COPY app/go.mod app/go.sum ./

# Download dependencies with verification
RUN go mod download && go mod verify

# Copy source code
COPY app/ .

# Build optimized static binary
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-w -s -X main.version=1.0.0" \
    -a -installsuffix cgo \
    -o grocery-app .

# Runtime stage
FROM alpine:latest

# Install CA certificates and create non-root user
RUN apk --no-cache add ca-certificates && \
    addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

WORKDIR /app

# Copy CA certificates from builder
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binary with proper ownership
COPY --from=builder --chown=appuser:appuser /build/grocery-app .

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Metadata
LABEL maintainer="your-email@example.com" \
      version="1.0.0" \
      description="Grocery List API"

# Run the application
CMD ["./grocery-app"]

