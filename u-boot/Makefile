.PHONY: build clean dist docker-build docker-promote

CONTAINER_NAME := muffin_u-boot
PROJECT ?= wiggly

docker-build:
	docker build -t $(PROJECT)/$(CONTAINER_NAME):latest .

docker-promote: docker-build
	docker tag $(PROJECT)/$(CONTAINER_NAME):latest $(PROJECT)/$(CONTAINER_NAME):build

build: docker-promote
	@echo "Stub: Building u-boot artifacts..."

clean:
	@echo "Stub: Cleaning u-boot artifacts..."

dist:
	@echo "Stub: Installing u-boot artifacts to dist/..."
