.PHONY: build clean dist docker-build docker-promote uboot-fetch build-matrix build-platform build-scr

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
	qemu_arm64:cortex-a72 
#	qemu_arm64:cortex-a76 \
#	rpi_4:cortex-a72 \
#	rpi_arm64:cortex-a76 \

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

	@echo "===> Building U-Boot for $(QEMU_CONF) on $(CPU)..."
	UBOOT_SCRIPT="u-boot.scr" envsubst < defconf_append.in > $(WORKING_DIR)/defconf_append
	cp $(CHECKOUT_DIR)/u-boot/configs/$(QEMU_CONF)_defconfig $(CHECKOUT_DIR)/u-boot/configs/$(QEMU_CONF)_$(PROJECT)_defconfig
	cat $(WORKING_DIR)/defconf_append >> $(CHECKOUT_DIR)/u-boot/configs/$(QEMU_CONF)_$(PROJECT)_defconfig
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
			make $(QEMU_CONF)_$(PROJECT)_defconfig && \
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

build-scr:
	KERNEL_IMAGE=vmlinuz-virt-3.21.3-actual \
	KERNEL_ADDR=0x40080000 \
	KERNEL_SIZE=$$(printf '0x%08X' 9585152) \
	DTB_IMAGE=virt-cortex-a72-1cpu-512M-dtc.dtb \
	DTB_ADDR=0x41000000 \
	DTB_SIZE=$$(printf '0x%08X' 398) \
	INITRD_IMAGE=initramfs-virt-3.21.3 \
	INITRD_ADDR=0x43000000 \
	INITRD_SIZE=$$(printf '0x%08X' 9433213) \
	BOOTARGS="console=ttyAMA0 earlycon root=/dev/vda" \
		envsubst '$$KERNEL_IMAGE $$KERNEL_ADDR $$KERNEL_SIZE $$DTB_IMAGE $$DTB_ADDR $$DTB_SIZE $$INITRD_IMAGE $$INITRD_ADDR $$INITRD_SIZE $$BOOTARGS' < \
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
