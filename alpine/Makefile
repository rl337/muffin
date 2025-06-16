.PHONY: init build clean dist docker-build docker-promote fetch-alpine-release-file verify-type verify-arch verify-alpine-version verify-alpine-release verify-filename verify-destination

CONTAINER_NAME := muffin_alpine
BASE_HTTP_URL := https://dl-cdn.alpinelinux.org/alpine
PROJECT ?= wiggly

BUILD_ROOT ?= $(realpath ../build)
CONTAINER_TAG := $(PROJECT)/$(CONTAINER_NAME)

ifndef DOWNLOADS_ROOT
$(error DOWNLOADS_ROOT is not set. Usage: $(MAKE) -C alpine DOWNLOADS_ROOT=value)
endif

ifndef ALPINE_VERSION
$(error ALPINE_VERSION is not set. Usage: $(MAKE) -C alpine ALPINE_VERSION=value)
endif

ifndef BUILD_ROOT
$(error BUILD_ROOT is not set. Usage: $(MAKE) -C alpine BUILD_ROOT=value)
endif

ifndef ARCH
$(error ARCH is not set. Usage: $(MAKE) -C alpine ARCH=value)
endif

ifndef SERVER_IP
$(error SERVER_IP is not set. Usage: $(MAKE) -C alpine SERVER_IP=value)
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

verify-alpine-release:
	@if [ -z "$(ALPINE_RELEASE)" ]; then \
		echo "ALPINE_RELEASE is not set"; \
		exit 1; \
	fi

verify-filename:
	@if [ -z "$(FILENAME)" ]; then \
		echo "FILENAME is not set"; \
		exit 1; \
	fi

verify-destination-dir:
	@if [ -z "$(DESTINATION_DIR)" ]; then \
		echo "DESTINATION_DIR is not set"; \
		exit 1; \
	fi

verify-destination-file:
	@if [ -z "$(DESTINATION_FILE)" ]; then \
		echo "DESTINATION_FILE is not set"; \
		exit 1; \
	fi

$(DOWNLOADS_ROOT)/%-$(ARCH)-$(ALPINE_VERSION): docker-promote verify-arch verify-alpine-version
	$(MAKE) fetch-alpine-release-file \
		ALPINE_RELEASE=netboot \
		FILENAME=$* \
		DESTINATION_DIR=$(DOWNLOADS_ROOT) \
		DESTINATION_FILE=$(@F)

$(BUILD_ROOT)/cmdline.txt: docker-promote verify-arch verify-alpine-version
	ALPINE_REPO_URL="http://$(SERVER_IP)/apks" \
	MODLOOP_URL="http://$(SERVER_IP)/modloop-rpi-$(ARCH)-$(ALPINE_VERSION)" \
	NOCLOUD_CONFIG_URL="http://$(SERVER_IP)/configs" \
	envsubst '$$ALPINE_REPO_URL $$MODLOOP_URL $$NOCLOUD_CONFIG_URL' < ./cmdline.txt.in > $(BUILD_ROOT)/cmdline.txt

$(BUILD_ROOT)/config.txt: docker-promote verify-arch verify-alpine-version
	KERNEL_FILE=vmlinuz-rpi-$(ARCH)-$(ALPINE_VERSION) \
	INITRAMFS_FILE=initramfs-rpi-$(ARCH)-$(ALPINE_VERSION) \
	envsubst '$$KERNEL_FILE $$INITRAMFS_FILE' < ./config.txt.in > $(BUILD_ROOT)/config.txt

build: init docker-promote \
	$(DOWNLOADS_ROOT)/vmlinuz-rpi-$(ARCH)-$(ALPINE_VERSION) \
	$(DOWNLOADS_ROOT)/initramfs-rpi-$(ARCH)-$(ALPINE_VERSION) \
	$(DOWNLOADS_ROOT)/modloop-rpi-$(ARCH)-$(ALPINE_VERSION) \
	$(BUILD_ROOT)/cmdline.txt \
	$(BUILD_ROOT)/config.txt

clean:
	@echo "Stub: Cleaning Alpine base images..."

dist: build
	cp $(BUILD_ROOT)/cmdline.txt $(TFTP_DIST)/
	cp $(BUILD_ROOT)/config.txt $(TFTP_DIST)/
	cp $(DOWNLOADS_ROOT)/vmlinuz-rpi-$(ARCH)-$(ALPINE_VERSION) $(TFTP_DIST)/
	cp $(DOWNLOADS_ROOT)/initramfs-rpi-$(ARCH)-$(ALPINE_VERSION) $(TFTP_DIST)/
	cp $(DOWNLOADS_ROOT)/modloop-rpi-$(ARCH)-$(ALPINE_VERSION) $(TFTP_DIST)/

