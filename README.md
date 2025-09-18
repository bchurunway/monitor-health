# Simple Health Monitor

A lightweight Docker container that monitors web application health and automatically restarts containers when health checks fail.

## Quick Start

```bash
docker run -d \
  --name app-monitor \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e HOST=localhost \
  -e PORT=80 \
  -e CONTAINER_NAME=myapp \
  yourusername/simple-health-monitor:latest
```

## Features

- ✅ **Lightweight** - 15MB Alpine-based image
- ✅ **Simple** - Just HTTP health checks and container restarts
- ✅ **Configurable** - All parameters via environment variables
- ✅ **Rate Limited** - Prevents restart storms with cooldowns
- ✅ **Production Ready** - Runs as non-root user

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HOST` | `localhost` | Target application hostname |
| `PORT` | `80` | Target application port |
| `ENDPOINT` | `/health` | Health check endpoint |
| `CONTAINER_NAME` | `app` | Name of container to restart |
| `CHECK_INTERVAL` | `30` | Seconds between health checks |
| `TIMEOUT` | `10` | HTTP request timeout (seconds) |
| `MAX_ATTEMPTS` | `3` | Failed checks before restart |
| `COOLDOWN` | `300` | Seconds between restarts (5 min) |

## Usage Examples

### Basic Usage

Monitor a local web app and restart its container:

```bash
docker run -d \
  --name health-monitor \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e CONTAINER_NAME=webapp \
  yourusername/simple-health-monitor:latest
```

### Custom Configuration

Monitor external service with custom settings:

```bash
docker run -d \
  --name api-monitor \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e HOST=192.168.1.100 \
  -e PORT=3000 \
  -e ENDPOINT=/api/health \
  -e CONTAINER_NAME=my-api-server \
  -e CHECK_INTERVAL=15 \
  -e MAX_ATTEMPTS=2 \
  yourusername/simple-health-monitor:latest
```

### Docker Compose

```yaml
version: '3.8'
services:
  health-monitor:
    image: yourusername/simple-health-monitor:latest
    container_name: health-monitor
    restart: unless-stopped
    environment:
      - HOST=localhost
      - PORT=80
      - ENDPOINT=/health
      - CONTAINER_NAME=webapp
      - CHECK_INTERVAL=30
      - TIMEOUT=10
      - MAX_ATTEMPTS=3
      - COOLDOWN=300
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    network_mode: host
```

## How It Works

1. **Health Check**: Sends HTTP GET request to `http://HOST:PORT/ENDPOINT`
2. **Failure Detection**: Counts consecutive failed health checks
3. **Container Restart**: Executes `docker restart CONTAINER_NAME` after MAX_ATTEMPTS failures
4. **Rate Limiting**: Enforces cooldown periods and maximum restarts per hour

## Output Example

```
Monitoring: http://localhost:80/health -> Container: webapp
Interval: 30s, Timeout: 10s, Max failures: 3
2025-01-15 10:30:15: Health check failed (1/3)
2025-01-15 10:30:45: Health check failed (2/3)
2025-01-15 10:31:15: Health check failed (3/3)
2025-01-15 10:31:15: Restarting container webapp
2025-01-15 10:31:16: Container restarted successfully
```

## Health Check Requirements

Your application's health endpoint should:
- Return HTTP 2xx status code when healthy
- Return HTTP 4xx/5xx status code when unhealthy
- Respond within the timeout period
- Be accessible from the monitor container

Example health endpoint responses:
- ✅ `HTTP 200 OK` - Application is healthy
- ❌ `HTTP 503 Service Unavailable` - Application is unhealthy
- ❌ Connection timeout - Application is unreachable

## Security Notes

- Runs as non-root user (`monitor`)
- Requires Docker socket access (read-only)
- Can restart any container on the host
- No network access except for health checks

## Rate Limiting

The monitor includes built-in protection against restart storms:

- **Maximum Restarts**: 3 per hour (configurable via MAX_ATTEMPTS)
- **Cooldown Period**: 5 minutes between restarts (configurable via COOLDOWN)
- **Automatic Reset**: Counters reset every hour

## Monitoring Multiple Applications

Deploy separate monitor containers for each application:

```bash
# Monitor webapp
docker run -d --name webapp-monitor \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e CONTAINER_NAME=webapp \
  yourusername/simple-health-monitor:latest

# Monitor api
docker run -d --name api-monitor \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e PORT=3000 -e CONTAINER_NAME=api \
  yourusername/simple-health-monitor:latest
```

## Troubleshooting

### Common Issues

**Container not found:**
```bash
# List running containers to find correct name
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

**Health endpoint not accessible:**
```bash
# Test health endpoint manually
curl -I http://localhost:80/health
```

**Permission denied:**
```bash
# Check Docker socket permissions
ls -la /var/run/docker.sock
# Should be readable by docker group
```

### Debugging

View monitor logs:
```bash
docker logs health-monitor
```

Test health endpoint:
```bash
docker exec health-monitor curl -f -v http://localhost:80/health
```

## Use Cases

- **Meteor/Node.js apps** deployed with MUP
- **Web APIs** that may hang or crash
- **Microservices** requiring high availability
- **Legacy applications** without built-in monitoring
- **Development environments** for automatic recovery

## Requirements

- Docker Engine 19.03+
- Target containers must be manageable via Docker socket
- Health endpoint must return proper HTTP status codes
- Network connectivity between monitor and target application

## Support

For issues and questions:
- GitHub: [Your Repository URL]
- Docker Hub: [This Repository]

## License

MIT License - see LICENSE file for details.