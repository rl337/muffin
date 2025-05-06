.PHONY: init build clean dist docker-build docker-promote get-latest-images scour verify-type verify-title

CONTAINER_NAME := muffin_alpine
PROJECT ?= wiggly

BUILD_ROOT ?= $(realpath ../build)
CONTAINER_TAG := $(PROJECT)/$(CONTAINER_NAME)

ifndef DOWNLOADS_ROOT
	$(error DOWNLOADS_ROOT is not set. Usage: $(MAKE) DOWNLOADS_ROOT=value)
endif

ifndef BUILD_ROOT
	$(error BUILD_ROOT is not set. Usage: $(MAKE) BUILD_ROOT=value)
endif

ifndef ALPINE_VERSION
	$(error ALPINE_VERSION is not set. Usage: $(MAKE) ALPINE_VERSION=value)
endif

docker-build:
	docker build -t $(CONTAINER_TAG):latest .

docker-promote: docker-build
	docker tag $(CONTAINER_TAG):latest $(CONTAINER_TAG):build


verify-type:
	@if [ -z "$(TYPE)" ]; then \
		echo "TYPE is not set"; \
		exit 1; \
	fi

verify-arch:
	@if [ -z "$(ARCH)" ]; then \
		echo "ARCH is not set"; \
		exit 1; \
	fi

verify-alpine-version:
	@if [ -z "$(ALPINE_VERSION)" ]; then \
		echo "ALPINE_VERSION is not set"; \
		exit 1; \
	fi

get-alpine-image: verify-type verify-arch verify-alpine-version docker-promote

	docker run --rm \
	    -v .:/app \
		-v $(DOWNLOADS_ROOT):/downloads \
		-v $(BUILD_ROOT):/build \
		$(CONTAINER_TAG):build \
		/bin/sh -c "cd /app && BUILD_DIR=/build DOWNLOAD_DIR=/downloads TYPE='$(TYPE)' TITLE='$(TITLE)' ALPINE_VERSION='$(ALPINE_VERSION)' ARCH='$(ARCH)' bash ./get-alpine.sh"


build: init docker-promote verify-type verify-arch
	@echo "Stub: Building Alpine base images..."

	$(MAKE) get-alpine-image TYPE=$(TYPE) ARCH=$(ARCH) ALPINE_VERSION=$(ALPINE_VERSION) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) BUILD_ROOT=$(BUILD_ROOT)

clean:
	rm -rf $(WORKING_DIR)

scour:
	rm -rf $(DOWNLOAD_DIR)

dist: build
	@echo "Stub: Installing Alpine outputs to dist/..."
	cp $(WORKING_DIR)/$(shell cat $(WORKING_DIR)/virt-meta.txt | grep UNPACK_NAME | cut -f 2 -d=)/boot/vmlinuz-virt \
	    $(TFTP_DIST)/vmlinuz-virt-$(shell cat $(WORKING_DIR)/virt-meta.txt | grep IMAGE_VERSION | cut -f 2 -d=)
	cp $(WORKING_DIR)/$(shell cat $(WORKING_DIR)/virt-meta.txt | grep UNPACK_NAME | cut -f 2 -d=)/boot/initramfs-virt \
	    $(TFTP_DIST)/initramfs-virt-$(shell cat $(WORKING_DIR)/virt-meta.txt | grep IMAGE_VERSION | cut -f 2 -d=)

	cp $(WORKING_DIR)/$(shell cat $(WORKING_DIR)/rpi-meta.txt | grep UNPACK_NAME | cut -f 2 -d=)/vmlinuz-rpi \
	    $(TFTP_DIST)/vmlinuz-rpi-$(shell cat $(WORKING_DIR)/rpi-meta.txt | grep IMAGE_VERSION | cut -f 2 -d=)
	cp $(WORKING_DIR)/$(shell cat $(WORKING_DIR)/rpi-meta.txt | grep UNPACK_NAME | cut -f 2 -d=)/initramfs-rpi \
	    $(TFTP_DIST)/initramfs-rpi-$(shell cat $(WORKING_DIR)/rpi-meta.txt | grep IMAGE_VERSION | cut -f 2 -d=)


