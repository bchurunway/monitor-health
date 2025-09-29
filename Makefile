# Variables
IMAGE_NAME = bchurunway/app-health-monitor
VERSION = 0.3
PLATFORMS = linux/amd64,linux/arm64

# Default target
.PHONY: help
help:
	@echo "Available commands:"
	@echo "  build-local    Build for current platform only"
	@echo "  build-multi    Build for multiple platforms"
	@echo "  push          Build and push to Docker Hub"
	@echo "  test          Test locally with docker-compose"
	@echo "  clean         Clean up local images"

# Build for current platform (for testing)
.PHONY: build-local
build-local:
	@echo "Building $(IMAGE_NAME):$(VERSION) for current platform..."
	docker build -t $(IMAGE_NAME):$(VERSION) .
	@echo "Build complete!"

# Build for multiple platforms (requires buildx)
.PHONY: build-multi
build-multi:
	@echo "Setting up buildx..."
	@docker buildx create --name multiplatform --use 2>/dev/null || docker buildx use multiplatform
	@echo "Building $(IMAGE_NAME):$(VERSION) for $(PLATFORMS)..."
	docker buildx build \
		--platform $(PLATFORMS) \
		-t $(IMAGE_NAME):$(VERSION) \
		-t $(IMAGE_NAME):latest \
		.
	@echo "Multi-platform build complete!"

# Build and push to Docker Hub
.PHONY: push
push:
	@echo "Building and pushing $(IMAGE_NAME):$(VERSION) to Docker Hub..."
	@docker buildx create --name multiplatform --use 2>/dev/null || docker buildx use multiplatform
	docker buildx build \
		--platform $(PLATFORMS) \
		-t $(IMAGE_NAME):$(VERSION) \
		-t $(IMAGE_NAME):latest \
		--push \
		.
	@echo "Push complete! Available at: https://hub.docker.com/r/$(IMAGE_NAME)"

# Test locally
.PHONY: test
test: build-local
	@echo "Starting test with docker-compose..."
	docker compose up -d
	@echo "Checking logs..."
	docker compose logs -f

# Stop test
.PHONY: stop-test
stop-test:
	docker compose down

# Clean up
.PHONY: clean
clean:
	@echo "Cleaning up..."
	docker image rm $(IMAGE_NAME):$(VERSION) 2>/dev/null || true
	docker image rm $(IMAGE_NAME):latest 2>/dev/null || true
	docker system prune -f
	@echo "Cleanup complete!"

# Update version
.PHONY: version
version:
	@read -p "Enter new version: " new_version; \
	sed -i 's/VERSION = .*/VERSION = '"$$new_version"'/' Makefile
	@echo "Version updated to $(VERSION)"