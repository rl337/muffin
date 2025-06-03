.PHONY: build clean dist docker-build docker-promote

ifndef PROJECT
$(error PROJECT is not set. Usage: $(MAKE) -C u-boot PROJECT=value)
endif

ifndef BUILD_ROOT
$(error BUILD_ROOT is not set. Usage: $(MAKE) -C u-boot BUILD_ROOT=value)
endif

ifndef DOWNLOADS_ROOT
$(error DOWNLOADS_ROOT is not set. Usage: $(MAKE) -C u-boot DOWNLOADS_ROOT=value)
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

verify-transfer-command:
	@if [ -z "$(TRANSFER_COMMAND)" ]; then \
		echo "TRANSFER_COMMAND is not set"; \
		exit 1; \
	fi

verify-server-ip:
	@if [ -z "$(SERVER_IP)" ]; then \
		echo "SERVER_IP is not set"; \
		exit 1; \
	fi

verify-kernel-image:
	@if [ -z "$(KERNEL_IMAGE)" ]; then \
		echo "KERNEL_IMAGE is not set"; \
		exit 1; \
	fi

verify-kernel-addr:
	@if [ -z "$(KERNEL_ADDR)" ]; then \
		echo "KERNEL_ADDR is not set"; \
		exit 1; \
	fi

verify-initrd-image:
	@if [ -z "$(INITRD_IMAGE)" ]; then \
		echo "INITRD_IMAGE is not set"; \
		exit 1; \
	fi


verify-initrd-addr:
	@if [ -z "$(INITRD_ADDR)" ]; then \
		echo "INITRD_ADDR is not set"; \
		exit 1; \
	fi

verify-initrd-size:
	@if [ -z "$(INITRD_SIZE)" ]; then \
		echo "INITRD_SIZE is not set"; \
		exit 1; \
	fi

verify-script-addr:
	@if [ -z "$(SCRIPT_ADDR)" ]; then \
		echo "SCRIPT_ADDR is not set"; \
		exit 1; \
	fi

verify-script-name:
	@if [ -z "$(UBOOT_SCRIPT)" ]; then \
		echo "UBOOT_SCRIPT is not set"; \
		exit 1; \
	fi

verify-bootargs:
	@if [ -z "$(BOOTARGS)" ]; then \
		echo "BOOTARGS is not set"; \
		exit 1; \
	fi

init: $(CHECKOUT_DIR)

docker-build:
	docker build -t $(CONTAINER_TAG):latest .

docker-promote: docker-build
	docker tag $(CONTAINER_TAG):latest $(CONTAINER_TAG):build

$(UBOOT_CONFIGS_DIR)/$(UBOOT_CONF)_$(PROJECT)_defconfig: verify-transfer-command verify-server-ip verify-script-addr verify-script-name
	UBOOT_SCRIPT="${UBOOT_SCRIPT}" \
	    TRANSFER_COMMAND="${TRANSFER_COMMAND}" \
	    SERVER_IP="${SERVER_IP}" \
	    SCRIPT_ADDR="${SCRIPT_ADDR}" \
	    envsubst < defconf_append.in > $(BUILD_ROOT)/defconf_append
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

build: init docker-promote verify-u-boot-conf verify-cpu 
ifndef UBOOT_CONF
	$(error UBOOT_CONF is not set)
endif
ifndef CPU
	$(error CPU is not set)
endif
	$(MAKE) $(BUILD_ROOT)/u-boot-$(UBOOT_CONF)-$(CPU).bin

	@echo "===> Built U-Boot for $(UBOOT_CONF) on $(CPU)..."



build-scr: verify-kernel-image verify-kernel-addr verify-initrd-image verify-initrd-addr verify-initrd-size verify-script-name verify-bootargs
	KERNEL_IMAGE=$(KERNEL_IMAGE) \
	KERNEL_ADDR=$(KERNEL_ADDR) \
	INITRD_ADDR=$(INITRD_ADDR) \
	INITRD_IMAGE=$(INITRD_IMAGE) \
	INITRD_SIZE=$(INITRD_SIZE) \
	BOOTARGS="$(BOOTARGS)" \
		envsubst '$$KERNEL_IMAGE $$KERNEL_ADDR $$INITRD_IMAGE $$INITRD_ADDR $$INITRD_SIZE $$BOOTARGS' < \
			./u-boot.cmd.in > $(BUILD_ROOT)/$(UBOOT_SCRIPT).cmd
	
	docker run --rm \
		-v $(BUILD_ROOT):/build \
		-v $(CHECKOUT_DIR):/checkout \
		$(CONTAINER_TAG):build \
		/bin/sh -c "\
			cd /checkout/u-boot/tools && \
			/checkout/u-boot/tools/mkimage \
				-A arm64 \
				-T script \
				-C none \
				-n 'U-Boot script' \
				-d /build/$(UBOOT_SCRIPT).cmd \
				/build/$(UBOOT_SCRIPT)"


clean:
	rm -rf $(WORKING_DIR)
	rm -rf $(DIST_ROOT)/u-boot

dist:
	mkdir -p $(DIST_ROOT)/u-boot
	cp $(BUILD_ROOT)/u-boot-*.bin $(DIST_ROOT)/u-boot/ || true
	cp $(BUILD_ROOT)/config-* $(DIST_ROOT)/u-boot/ || true
