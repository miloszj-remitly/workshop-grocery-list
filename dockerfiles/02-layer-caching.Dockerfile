# Example 2: Optimized Layer Caching
# ===================================
# Pros:
#   - Better build caching (dependencies cached separately)
#   - Faster rebuilds when only code changes
#   - Still simple to understand
# Cons:
#   - Still large image size (~800MB)
#   - Includes build tools in production
#   - Security risk (more attack surface)
#
# Key Improvement:
#   - Dependencies are downloaded in a separate layer
#   - Only re-downloads deps when go.mod/go.sum changes
#   - Code changes don't invalidate dependency cache

FROM golang:1.23-alpine

WORKDIR /app

# Copy dependency files first (changes less frequently)
COPY app/go.mod app/go.sum ./

# Download dependencies (cached layer)
RUN go mod download

# Copy source code (changes more frequently)
COPY app/ .

# Build the application
RUN go build -o grocery-app .

# Expose port
EXPOSE 8080

# Run the application
CMD ["./grocery-app"]

