FROM alpine:3.18

RUN apk add --no-cache bash curl docker-cli
RUN addgroup -g 1001 monitor && \
    adduser -D -u 1001 -G monitor monitor && \
    addgroup docker && \
    addgroup monitor docker

COPY monitor.sh /monitor.sh
RUN chmod +x /monitor.sh

USER monitor

ENV HOST=localhost \
    PORT=80 \
    ENDPOINT=/_internal/status \
    CONTAINER_NAME=app \
    CHECK_INTERVAL=30 \
    TIMEOUT=10 \
    MAX_ATTEMPTS=3 \
    COOLDOWN=300

CMD ["/monitor.sh"]