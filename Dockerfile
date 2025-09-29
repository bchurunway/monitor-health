FROM alpine:3.18

# Install dependencies
RUN apk add --no-cache bash curl docker-cli

# Create monitor user
RUN addgroup -g 1001 monitor && \
    adduser -D -u 1001 -G monitor monitor

# Copy scripts
COPY entrypoint.sh /entrypoint.sh
COPY monitor.sh /monitor.sh

# Make scripts executable
RUN chmod +x /entrypoint.sh /monitor.sh

# Environment defaults
ENV HOST=localhost \
    PORT=80 \
    ENDPOINT=/health \
    CONTAINER_NAME=app \
    CHECK_INTERVAL=30 \
    TIMEOUT=10 \
    MAX_ATTEMPTS=3 \
    COOLDOWN=300

# Use entrypoint to handle Docker socket permissions
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/monitor.sh"]
