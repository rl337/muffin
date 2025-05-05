.PHONY: build clean dist docker-build docker-promote build-scr

ifndef PROJECT
$(error PROJECT is not set. Usage: $(MAKE) PROJECT=value)
endif

ifndef BUILD_ROOT
$(error BUILD_ROOT is not set. Usage: $(MAKE) BUILD_ROOT=value)
endif

ifndef DOWNLOADS_ROOT
$(error DOWNLOADS_ROOT is not set. Usage: $(MAKE) DOWNLOADS_ROOT=value)
endif

CHECKOUT_DIR := $(DOWNLOADS_ROOT)/u-boot

UBOOT_VERSION ?= v2025.01

CONTAINER_NAME := muffin_u-boot
CONTAINER_TAG := $(PROJECT)/$(CONTAINER_NAME)
UBOOT_REPO ?= https://source.denx.de/u-boot/u-boot.git
UBOOT_CONFIGS_DIR := $(CHECKOUT_DIR)/u-boot/configs

DIST_ROOT ?= $(realpath ../dist)

$(CHECKOUT_DIR):
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



verify-u-boot-conf:
	@if [ -z "$(UBOOT_CONF)" ]; then \
		echo "UBOOT_CONF is not set"; \
		exit 1; \
	fi

verify-cpu:
	@if [ -z "$(CPU)" ]; then \
		echo "CPU is not set"; \
		exit 1; \
	fi

init: $(CHECKOUT_DIR)

docker-build:
	docker build -t $(CONTAINER_TAG):latest .

docker-promote: docker-build
	docker tag $(CONTAINER_TAG):latest $(CONTAINER_TAG):build

$(UBOOT_CONFIGS_DIR)/$(UBOOT_CONF)_$(PROJECT)_defconfig:
	UBOOT_SCRIPT="u-boot.scr" envsubst < defconf_append.in > $(BUILD_ROOT)/defconf_append
	cp $(CHECKOUT_DIR)/u-boot/configs/$(UBOOT_CONF)_defconfig $(CHECKOUT_DIR)/u-boot/configs/$(UBOOT_CONF)_$(PROJECT)_defconfig
	cat $(BUILD_ROOT)/defconf_append >> $(CHECKOUT_DIR)/u-boot/configs/$(UBOOT_CONF)_$(PROJECT)_defconfig

$(BUILD_ROOT)/u-boot-$(UBOOT_CONF)-$(CPU).bin: $(UBOOT_CONFIGS_DIR)/$(UBOOT_CONF)_$(PROJECT)_defconfig
	docker run --rm \
		-v $(BUILD_ROOT):/build \
		-v .:/app \
		-v $(CHECKOUT_DIR):/checkout \
		-w /checkout/u-boot \
		$(CONTAINER_TAG):build \
		/bin/sh -c "\
			set -e; \
			make distclean && \
			make $(UBOOT_CONF)_$(PROJECT)_defconfig && \
			make CROSS_COMPILE=aarch64-none-elf- CFLAGS=\"-O2 -mcpu=$(CPU)\" -j4 && \
			cp .config /build/config-$(UBOOT_CONF)-$(CPU) && \
			cp u-boot.bin /build/u-boot-$(UBOOT_CONF)-$(CPU).bin"

build: init docker-promote verify-u-boot-conf verify-cpu $(BUILD_ROOT)/u-boot-$(UBOOT_CONF)-$(CPU).bin
ifndef UBOOT_CONF
	$(error UBOOT_CONF is not set)
endif
ifndef CPU
	$(error CPU is not set)
endif

	@echo "===> Built U-Boot for $(UBOOT_CONF) on $(CPU)..."



build-scr:
	KERNEL_IMAGE=vmlinuz-virt-3.21.3 \
	KERNEL_ADDR=0x40200000 \
	INITRD_ADDR=0x42D00000 \
	INITRD_IMAGE=initramfs-virt-3.21.3 \
	INITRD_SIZE=$$(printf '0x%08X' 9433213) \
	BOOTARGS="console=ttyAMA0 earlycon root=/dev/vda1" \
		envsubst '$$KERNEL_IMAGE $$KERNEL_ADDR $$INITRD_IMAGE $$INITRD_ADDR $$INITRD_SIZE $$BOOTARGS' < \
		    ./u-boot.cmd.in > $(WORKING_DIR)/u-boot.cmd
	
	docker run --rm \
		-v $(WORKING_DIR):/build \
		$(CONTAINER_TAG):build \
		/bin/sh -c "\
			cd /build && \
			/build/checkout/u-boot/tools/mkimage \
				-A arm64 \
				-T script \
				-C none \
				-n 'U-Boot script' \
				-d /build/u-boot.cmd \
				/build/u-boot.scr"


clean:
	rm -rf $(WORKING_DIR)
	rm -rf $(DIST_ROOT)/u-boot

dist:
	mkdir -p $(DIST_ROOT)/u-boot
	cp $(BUILD_ROOT)/u-boot/u-boot-*.bin $(DIST_ROOT)/u-boot/ || true
	cp $(BUILD_ROOT)/u-boot/config-* $(DIST_ROOT)/u-boot/ || true
