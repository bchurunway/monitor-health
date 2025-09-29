#!/bin/bash
# entrypoint.sh - Handle Docker socket permissions dynamically

set -e

echo "Setting up Docker socket permissions..."

# Get the group ID of the mounted Docker socket
DOCKER_SOCKET_GID=$(stat -c '%g' /var/run/docker.sock 2>/dev/null || echo "")

if [ -n "$DOCKER_SOCKET_GID" ] && [ "$DOCKER_SOCKET_GID" != "0" ]; then
    echo "Docker socket found with GID: $DOCKER_SOCKET_GID"
    
    # Create or update docker group with the correct GID
    if ! getent group docker >/dev/null 2>&1; then
        echo "Creating docker group with GID $DOCKER_SOCKET_GID"
        addgroup -g "$DOCKER_SOCKET_GID" docker
    else
        echo "Docker group exists, updating GID to $DOCKER_SOCKET_GID"
        groupmod -g "$DOCKER_SOCKET_GID" docker 2>/dev/null || true
    fi
    
    # Add monitor user to docker group
    addgroup monitor docker 2>/dev/null || true
    echo "Added monitor user to docker group"
    
    # Verify access
    if su -s /bin/sh monitor -c "docker version >/dev/null 2>&1"; then
        echo "Docker socket access confirmed"
    else
        echo "Warning: Docker socket access test failed"
    fi
else
    echo "Warning: Docker socket not found or owned by root"
fi

echo "Starting health monitor..."

# Execute the command as monitor user
exec su -s /bin/bash monitor -c "exec $*"