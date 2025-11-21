# Builder
FROM golang:1.25 AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
# Build with debug flags
RUN CGO_ENABLED=0 GOOS=linux go build -gcflags "all=-N -l" -o identity-example .

# Final image
FROM debian:bookworm-slim

WORKDIR /app
COPY --from=builder /app/identity-example /app/identity-example

EXPOSE 8080

ENTRYPOINT ["/app/identity-example"]
