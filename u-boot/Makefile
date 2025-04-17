.PHONY: build clean dist docker-build docker-promote uboot-fetch build-matrix build-platform

PROJECT ?= wiggly
UBOOT_VERSION ?= v2025.01

CONTAINER_NAME := muffin_u-boot
CONTAINER_TAG := $(PROJECT)/$(CONTAINER_NAME)
UBOOT_REPO ?= https://source.denx.de/u-boot/u-boot.git

BUILD_ROOT ?= $(realpath ../build)
DIST_ROOT ?= $(realpath ../dist)

WORKING_DIR := $(BUILD_ROOT)/u-boot
CHECKOUT_DIR := $(WORKING_DIR)/checkout

UBOOT_BUILD_MATRIX := \
	rpi_4:cortex-a72 \
	qemu_arm64:cortex-a76 \
	qemu_arm64:cortex-a72 \
	rpi_arm64:cortex-a76

init:
	mkdir -p $(WORKING_DIR)
	mkdir -p $(CHECKOUT_DIR)

docker-build:
	docker build -t $(CONTAINER_TAG):latest .

docker-promote: docker-build
	docker tag $(CONTAINER_TAG):latest $(CONTAINER_TAG):build

uboot-fetch:
	docker run --rm \
		-v $(CHECKOUT_DIR):/checkout \
		$(CONTAINER_TAG):build \
		/bin/sh -c "\
			cd /checkout && \
			if [ ! -d u-boot ]; then \
				git clone $(UBOOT_REPO) && \
				cd u-boot && \
				git checkout $(UBOOT_VERSION); \
			else \
				echo 'U-Boot source already exists, skipping clone.'; \
			fi"

build-platform: docker-promote
ifndef QEMU_CONF
	$(error QEMU_CONF is not set)
endif
ifndef CPU
	$(error CPU is not set)
endif

	[ -f $(WORKING_DIR)/u-boot-$(QEMU_CONF)-$(CPU).bin ] || \
		docker run --rm \
			-v $(WORKING_DIR):/build \
		-v .:/app \
		-v $(CHECKOUT_DIR):/checkout \
		-w /checkout/u-boot \
		$(CONTAINER_TAG):build \
		/bin/sh -c "\
			set -e; \
			make distclean && \
			make $(QEMU_CONF)_defconfig && \
			make CROSS_COMPILE=aarch64-none-elf- CFLAGS=\"-O2 -mcpu=$(CPU)\" -j4 && \
			cp .config /build/config-$(QEMU_CONF)-$(CPU) && \
			cp u-boot.bin /build/u-boot-$(QEMU_CONF)-$(CPU).bin"


build-matrix: docker-promote uboot-fetch
	@for entry in $(UBOOT_BUILD_MATRIX); do \
		CONF=$${entry%%:*}; \
		CPU=$${entry##*:}; \
		echo "===> Building U-Boot for $$CONF on $$CPU..."; \
		$(MAKE) build-platform QEMU_CONF=$$CONF CPU=$$CPU || exit 1; \
	done

build: init build-matrix

clean:
	rm -rf $(WORKING_DIR)
	rm -rf $(DIST_ROOT)/u-boot

dist:
	mkdir -p $(DIST_ROOT)/u-boot
	cp $(BUILD_ROOT)/u-boot/u-boot-*.bin $(DIST_ROOT)/u-boot/ || true
	cp $(BUILD_ROOT)/u-boot/config-* $(DIST_ROOT)/u-boot/ || true
