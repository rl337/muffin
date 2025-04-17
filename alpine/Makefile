.PHONY: init build clean dist docker-build docker-promote get-latest-images

CONTAINER_NAME := muffin_alpine
PROJECT ?= wiggly

BUILD_ROOT ?= $(realpath ../build)
DIST_ROOT ?= $(realpath ../dist)

WORKING_DIR ?= $(BUILD_ROOT)/alpine
DOWNLOAD_DIR ?= $(WORKING_DIR)/downloads

CONTAINER_TAG := $(PROJECT)/$(CONTAINER_NAME)

init:
	mkdir -p $(WORKING_DIR)
	mkdir -p $(DOWNLOAD_DIR)

docker-build:
	docker build -t $(CONTAINER_TAG):latest .

docker-promote: docker-build
	docker tag $(CONTAINER_TAG):latest $(CONTAINER_TAG):build

get-latest-images:
	docker run --rm \
	    -v .:/app \
		-v $(WORKING_DIR):/working \
		-v $(DOWNLOAD_DIR):/downloads \
		$(CONTAINER_TAG):build \
		/bin/sh -c "cd /app && WORKING_DIR=/working DOWNLOAD_DIR=/downloads bash ./get-latest.sh"

build: init docker-promote get-latest-images
	@echo "Stub: Building Alpine base images..."
	
clean:
	rm -rf $(WORKING_DIR)
	rm -rf $(DOWNLOAD_DIR)

dist:
	@echo "Stub: Installing Alpine outputs to dist/..."
