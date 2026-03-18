# Example 5: Scratch Base (Minimal Possible)
# ============================================
# Pros:
#   - Absolute smallest image (~5-8MB)
#   - Maximum security (literally nothing but your app)
#   - Fastest startup time
# Cons:
#   - No shell, no debugging tools
#   - No CA certificates (HTTPS won't work without adding them)
#   - Hardest to debug
#   - Need to manually add any runtime dependencies
#
# Key Improvements:
#   - Uses "scratch" (empty base image)
#   - Only contains the binary
#   - Must manually add CA certs for HTTPS

# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /build

# Copy dependency files first
COPY app/go.mod app/go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY app/ .

# Build fully static binary
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-w -s" \
    -a -installsuffix cgo \
    -o grocery-app .

# Runtime stage - scratch (empty)
FROM scratch

# Copy CA certificates for HTTPS (if needed)
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binary
COPY --from=builder /build/grocery-app /grocery-app

# Expose port
EXPOSE 8080

# Run the application
CMD ["/grocery-app"]

