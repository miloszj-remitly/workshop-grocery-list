# Example 4: Distroless Base Image
# ==================================
# Pros:
#   - Even smaller image (~10MB)
#   - Maximum security (no shell, no package manager)
#   - Only contains app and runtime dependencies
#   - Google-maintained base images
# Cons:
#   - Cannot exec into container for debugging
#   - No shell for troubleshooting
#   - Harder to debug issues
#
# Key Improvements:
#   - Uses Google's distroless base image
#   - Contains only CA certs and minimal runtime
#   - Best for production security

# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /build

# Copy dependency files first
COPY app/go.mod app/go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY app/ .

# Build static binary with optimizations
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-w -s" \
    -o grocery-app .

# Runtime stage - distroless
FROM gcr.io/distroless/static-debian12

WORKDIR /app

# Copy binary from builder
COPY --from=builder /build/grocery-app .

# Expose port
EXPOSE 8080

# Run the application
CMD ["./grocery-app"]

