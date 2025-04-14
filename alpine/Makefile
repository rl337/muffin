.PHONY: build clean dist docker-build docker-promote get-latest-images

CONTAINER_NAME := muffin_alpine
PROJECT ?= wiggly

BUILD_ROOT ?= $(realpath ../build)
DIST_ROOT ?= $(realpath ../dist)

CONTAINER_TAG := $(PROJECT)/$(CONTAINER_NAME)

docker-build:
	docker build -t $(CONTAINER_TAG):latest .

docker-promote: docker-build
	docker tag $(CONTAINER_TAG):latest $(CONTAINER_TAG):build

get-latest-images:
	docker run --rm \
		-v $(BUILD_ROOT):/build \
		-v .:/app \
		-e WORKING_DIR=/build \
		$(CONTAINER_TAG):build \
		/bin/sh -c "cd /app && bash ./get-latest.sh"

build: docker-promote get-latest-images
	@echo "Stub: Building Alpine base images..."
	
clean:
	@echo "Stub: Cleaning Alpine builds..."

dist:
	@echo "Stub: Installing Alpine outputs to dist/..."
