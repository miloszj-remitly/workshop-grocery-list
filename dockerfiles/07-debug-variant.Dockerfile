# Example 7: Debug Variant with Build Args
# ==========================================
# Pros:
#   - Can build both debug and production images
#   - Debug symbols optional via build arg
#   - Flexible for different environments
#   - Can include debugging tools when needed
# Cons:
#   - More complex build process
#   - Need to manage build arguments
#
# Usage:
#   Production: docker build -f 07-debug-variant.Dockerfile .
#   Debug:      docker build -f 07-debug-variant.Dockerfile --build-arg DEBUG=true .
#
# Key Improvements:
#   - Build arguments for flexibility
#   - Conditional debug symbols
#   - Optional debugging tools

# Build stage
FROM golang:1.23-alpine AS builder

# Build argument for debug mode
ARG DEBUG=false

WORKDIR /build

# Install build dependencies
RUN apk --no-cache add ca-certificates git

# Copy dependency files
COPY app/go.mod app/go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY app/ .

# Build with conditional flags based on DEBUG arg
RUN if [ "$DEBUG" = "true" ] ; then \
        echo "Building with debug symbols..." && \
        CGO_ENABLED=0 GOOS=linux go build -gcflags="all=-N -l" -o grocery-app . ; \
    else \
        echo "Building optimized binary..." && \
        CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o grocery-app . ; \
    fi

# Runtime stage
FROM alpine:latest

ARG DEBUG=false

WORKDIR /app

# Install runtime dependencies
RUN apk --no-cache add ca-certificates

# Conditionally install debugging tools
RUN if [ "$DEBUG" = "true" ] ; then \
        apk --no-cache add curl wget busybox-extras ; \
    fi

# Copy binary
COPY --from=builder /build/grocery-app .

# Expose port
EXPOSE 8080

# Run the application
CMD ["./grocery-app"]

