#!/bin/bash
# monitor.sh - Simple Health Monitor

# Config from environment
HOST="${HOST:-localhost}"
PORT="${PORT:-80}"
ENDPOINT="${ENDPOINT:-/health}"
CONTAINER_NAME="${CONTAINER_NAME:-app}"
CHECK_INTERVAL="${CHECK_INTERVAL:-300}"
TIMEOUT="${TIMEOUT:-30}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-3}"
COOLDOWN="${COOLDOWN:-300}"

# State tracking
LAST_RESTART=0
RESTART_COUNT=0
WINDOW_START=0
FAILURES=0

# Build URL
URL="http://${HOST}:${PORT}${ENDPOINT}"

echo "Monitoring: $URL -> Container: $CONTAINER_NAME"
echo "Interval: ${CHECK_INTERVAL}s, Timeout: ${TIMEOUT}s, Max failures: $MAX_ATTEMPTS"

# Check if we can restart (rate limiting)
can_restart() {
    local now=$(date +%s)
    
    # Reset window every hour
    if [[ $((now - WINDOW_START)) -gt 3600 ]]; then
        RESTART_COUNT=0
        WINDOW_START=$now
    fi
    
    # Check max attempts
    [[ $RESTART_COUNT -lt $MAX_ATTEMPTS ]] || return 1
    
    # Check cooldown
    [[ $((now - LAST_RESTART)) -gt $COOLDOWN ]] || return 1
    
    return 0
}

# Restart container
restart_container() {
    echo "$(date): Restarting container $CONTAINER_NAME"
    
    if ! can_restart; then
        echo "$(date): Restart blocked (rate limit or cooldown)"
        return 1
    fi
    
    if docker restart "$CONTAINER_NAME"; then
        LAST_RESTART=$(date +%s)
        RESTART_COUNT=$((RESTART_COUNT + 1))
        FAILURES=0
        echo "$(date): Container restarted successfully"
        sleep 30  # Wait for startup
    else
        echo "$(date): Failed to restart container"
    fi
}

# Main monitoring loop
while true; do
    if curl -f -s -m "$TIMEOUT" "$URL" >/dev/null 2>&1; then
        # Health check passed
        FAILURES=0
    else
        # Health check failed
        FAILURES=$((FAILURES + 1))
        echo "$(date): Health check failed ($FAILURES/$MAX_ATTEMPTS)"
        
        if [[ $FAILURES -ge $MAX_ATTEMPTS ]]; then
            restart_container
        fi
    fi
    
    sleep "$CHECK_INTERVAL"
done