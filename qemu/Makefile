.PHONY: build clean dist docker-build docker-promote

CONTAINER_NAME := muffin_qemu
PROJECT ?= wiggly

docker-build:
	docker build -t $(PROJECT)/$(CONTAINER_NAME):latest .

docker-promote: docker-build
	docker tag $(PROJECT)/$(CONTAINER_NAME):latest $(PROJECT)/$(CONTAINER_NAME):build

build: docker-promote
	@echo "Stub: Building QEMU disk images..."

clean:
	@echo "Stub: Cleaning QEMU images..."

dist:
	@echo "Stub: Installing QEMU artifacts to dist/..."
