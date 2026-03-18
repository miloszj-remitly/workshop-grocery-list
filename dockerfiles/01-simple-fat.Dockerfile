# Example 1: Simple "Fat" Dockerfile
# ====================================
# Pros:
#   - Simple and easy to understand
#   - Fast to write
# Cons:
#   - Large image size (~800MB with Go toolchain)
#   - Includes unnecessary build tools in production
#   - No layer caching optimization
#   - Security risk (more attack surface)

FROM golang:1.23-alpine

WORKDIR /app

# Copy everything at once
COPY app/ .

# Download dependencies and build in one layer
RUN go mod download && \
    go build -o grocery-app .

# Expose port
EXPOSE 8080

# Run the application
CMD ["./grocery-app"]

