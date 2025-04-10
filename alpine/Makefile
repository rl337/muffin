.PHONY: build clean dist docker-build docker-promote

CONTAINER_NAME := muffin_alpine
PROJECT ?= wiggly

docker-build:
	docker build -t $(PROJECT)/$(CONTAINER_NAME):latest .

docker-promote: docker-build
	docker tag $(PROJECT)/$(CONTAINER_NAME):latest $(PROJECT)/$(CONTAINER_NAME):build

build: docker-promote
	@echo "Stub: Building Alpine base images..."
	
clean:
	@echo "Stub: Cleaning Alpine builds..."

dist:
	@echo "Stub: Installing Alpine outputs to dist/..."
