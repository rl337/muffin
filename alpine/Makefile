.PHONY: build clean dist docker-build docker-promote fetch-alpine-release-file refresh-apk-mirror verify-type verify-arch verify-alpine-version verify-alpine-release verify-filename verify-destination

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

ifndef HARDWARE
$(error HARDWARE is not set. Usage: $(MAKE) -C alpine HARDWARE=value)
endif

ifndef SERVER_IP
$(error SERVER_IP is not set. Usage: $(MAKE) -C alpine SERVER_IP=value)
endif

APKS_DIRECTORY := $(DOWNLOADS_ROOT)/apks/$(ALPINE_VERSION)/$(ARCH)
APKS_REPOSITORY := $(DOWNLOADS_ROOT)/apks/$(ALPINE_VERSION)/

PLATFORM_linux/aarch64  := linux/arm64
PLATFORM_linux/x86_64   := linux/amd64
PLATFORM := $(PLATFORM_linux/$(ARCH))


docker-build:
	docker build --platform=$(PLATFORM) -t $(CONTAINER_TAG):latest .

docker-promote: docker-build
	docker tag $(CONTAINER_TAG):latest $(CONTAINER_TAG):build


verify-%:
	@if [ -z "$($*)" ]; then \
		echo "$* is not set"; \
		exit 1; \
	fi


fetch-alpine-release-file: docker-promote verify-ALPINE_RELEASE verify-ARCH verify-ALPINE_VERSION verify-FILENAME verify-DESTINATION_DIR verify-DESTINATION_FILE
	@echo "Downloading Alpine $(ALPINE_RELEASE) file $(FILENAME)..."
	docker run --platform=$(PLATFORM) --rm \
		-v $(DESTINATION_DIR):/downloads \
		$(CONTAINER_TAG):build \
		/bin/sh -c "wget $(BASE_HTTP_URL)/$(ALPINE_VERSION)/releases/$(ARCH)/$(ALPINE_RELEASE)/$(FILENAME) -O /downloads/$(DESTINATION_FILE)"

refresh-apk-mirror: docker-promote verify-ARCH verify-ALPINE_VERSION
	mkdir -p $(APKS_DIRECTORY) && \
	docker run --platform=$(PLATFORM) --rm \
		-v $(APKS_REPOSITORY):/apks \
		-v $(BUILD_ROOT):/build \
		-v .:/app \
		$(CONTAINER_TAG):build \
		/bin/sh -cx "apk update && \
		    apk --simulate add $$(cat required_packages.txt | tr '\n' ' ') | \
			    grep -v 'OK' | cut -f3 -d\  > /build/full-package-list-$(ARCH).txt && \
			apk fetch --recursive --output /apks/$(ARCH) \`cat /build/full-package-list-$(ARCH).txt | tr '\n' ' '\` && \
			apk index --rewrite-arch $(ARCH) -o /apks/$(ARCH)/APKINDEX.tar.gz /apks/$(ARCH)/*.apk"

$(BUILD_ROOT)/apkovl-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION).tar.gz: refresh-apk-mirror
	docker run --platform=$(PLATFORM) --rm \
		-v $(BUILD_ROOT):/build \
		-v $(APKS_REPOSITORY):/apks \
		$(CONTAINER_TAG):build \
		/bin/sh -cx "\
			apk --root /build/apkovl-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) --verbose --verbose --allow-untrusted --repository /apks --initdb add $$(cat required_packages.txt | tr '\n' ' ') && \
			tar -czf /build/apkovl-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION).tar.gz -C /build/apkovl-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) ."

$(DOWNLOADS_ROOT)/%-$(ARCH)-$(ALPINE_VERSION): 
	$(MAKE) verify-ARCH 
	$(MAKE) verify-ALPINE_VERSION 
	$(MAKE) fetch-alpine-release-file \
		ALPINE_RELEASE=netboot \
		FILENAME=$* \
		DESTINATION_DIR=$(DOWNLOADS_ROOT) \
		DESTINATION_FILE=$(@F)

$(BUILD_ROOT)/cmdline.txt: cmdline.txt.in
	$(MAKE) verify-ARCH 
	$(MAKE) verify-ALPINE_VERSION 
	ALPINE_REPO_URL="http://$(SERVER_IP)/apks/$(ALPINE_VERSION)" \
		MODLOOP_URL="http://$(SERVER_IP)/modloop-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION)" \
		NOCLOUD_CONFIG_URL="http://$(SERVER_IP)/configs" \
		APKOVL_URL="http://$(SERVER_IP)/apkovl-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION).tar.gz" \
		envsubst '$$ALPINE_REPO_URL $$MODLOOP_URL $$NOCLOUD_CONFIG_URL $$APKOVL_URL' < ./cmdline.txt.in > $(BUILD_ROOT)/cmdline.txt

$(BUILD_ROOT)/config.txt: cmdline.txt.in
	$(MAKE) verify-ARCH 
	$(MAKE) verify-ALPINE_VERSION 
	KERNEL_FILE=vmlinuz-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) \
		INITRAMFS_FILE=initramfs-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) \
		envsubst '$$KERNEL_FILE $$INITRAMFS_FILE' < ./config.txt.in > $(BUILD_ROOT)/config.txt

build: $(BUILD_ROOT)/apkovl-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION).tar.gz \
	$(DOWNLOADS_ROOT)/vmlinuz-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) \
	$(DOWNLOADS_ROOT)/initramfs-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) \
	$(DOWNLOADS_ROOT)/modloop-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) \
	$(BUILD_ROOT)/cmdline.txt \
	$(BUILD_ROOT)/config.txt

clean:
	@echo "Stub: Cleaning Alpine base images..."

dist: build
	if [ "$(HARDWARE)" == "rpi" ]; then \
		cp $(BUILD_ROOT)/cmdline.txt $(TFTP_DIST)/; \
		cp $(BUILD_ROOT)/config.txt $(TFTP_DIST)/; \
	fi

	cp $(BUILD_ROOT)/apkovl-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION).tar.gz $(TFTP_DIST)/
	cp $(DOWNLOADS_ROOT)/vmlinuz-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) $(TFTP_DIST)/
	cp $(DOWNLOADS_ROOT)/initramfs-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) $(TFTP_DIST)/
	cp $(DOWNLOADS_ROOT)/modloop-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) $(TFTP_DIST)/

	rsync -avz $(APKS_DIRECTORY)/ $(TFTP_DIST)/apks/$(ALPINE_VERSION)/$(ARCH)/

