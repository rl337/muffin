.PHONY: build clean dist docker-build docker-promote create-qcow2 run

BUILD_ROOT ?= $(realpath ../build)
DIST_ROOT ?= $(realpath ../dist)
TFTP_DIST ?= $(DIST_ROOT)/tftp

CONTAINER_NAME := muffin_qemu
PROJECT ?= wiggly

WORKING_DIR := $(BUILD_ROOT)/qemu
ALPINE_DIR := $(BUILD_ROOT)/alpine
UBOOT_DIR := $(BUILD_ROOT)/u-boot
CHECKOUT_DIR := $(WORKING_DIR)/checkout

CONTAINER_TAG := $(PROJECT)/$(CONTAINER_NAME)

docker-build:
	docker build -t $(CONTAINER_TAG):latest .

docker-promote: docker-build
	docker tag $(CONTAINER_TAG):latest $(CONTAINER_TAG):build

create-qcow2:
	if [ -z "$(TARGET_FILE)" ]; then \
		echo "TARGET_FILE is not set"; \
		exit 1; \
	fi
	if [ -z "$(SIZE)" ]; then \
		echo "SIZE is not set"; \
		exit 1; \
	fi
	docker run --rm \
		-v $(WORKING_DIR):/build \
		$(CONTAINER_TAG):build \
		qemu-img create -f qcow2 /build/$(TARGET_FILE) $(SIZE)

run: docker-promote 
	ls -l $(WORKING_DIR)

	docker run -it --rm \
		-v $(WORKING_DIR):/build \
		-v $(ALPINE_DIR):/alpine \
		-v $(UBOOT_DIR):/u-boot \
		-v $(TFTP_DIST):/tftp \
		$(CONTAINER_TAG):build \
		qemu-system-aarch64 \
			-d guest_errors \
			-machine virt \
			-cpu cortex-a72 \
			-m 512M \
			-nographic \
			-device virtio-net-device,id=net0dev,netdev=net0 \
			-netdev user,id=net0,tftp=/tftp,bootfile=u-boot.scr \
			-drive file=/build/virt-hd0.qcow2,media=disk,format=qcow2 \
			-bios /u-boot/u-boot-qemu_arm64-cortex-a72.bin 

build: docker-promote 
	@echo "Stub: Building QEMU disk images..."

clean:
	@echo "Stub: Cleaning QEMU images..."
	rm -rf $(WORKING_DIR)
	rm -rf $(DIST_ROOT)/qemu

dist:
	@echo "Stub: Installing QEMU artifacts to dist/..."
	mkdir -p $(DIST_ROOT)/qemu
	cp $(WORKING_DIR)/*.dtb $(TFTP_DIST)/
