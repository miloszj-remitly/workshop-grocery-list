# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /build

# Copy only the app directory
COPY app/ .

# Download dependencies
RUN go mod download

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o grocery-app .

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /build/grocery-app .

# Expose port
EXPOSE 8080

# Run the application
CMD ["./grocery-app"]


