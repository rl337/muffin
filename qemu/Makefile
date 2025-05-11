.PHONY: build clean dist docker-build docker-promote create-qcow2 run

ifndef DOWNLOADS_ROOT
	$(error DOWNLOADS_ROOT is not set. Usage: $(MAKE) -C alpine DOWNLOADS_ROOT=value)
endif

ifndef BUILD_ROOT
	$(error BUILD_ROOT is not set. Usage: $(MAKE) -C alpine BUILD_ROOT=value)
endif

ifndef ALPINE_BUILD
	$(error ALPINE_BUILD is not set. Usage: $(MAKE) -C alpine ALPINE_BUILD=value)
endif

ifndef UBOOT_BUILD
	$(error UBOOT_BUILD is not set. Usage: $(MAKE) -C u-boot UBOOT_BUILD=value)
endif

ifndef TFTP_DIST
	$(error TFTP_DIST is not set. Usage: $(MAKE) -C qemu TFTP_DIST=value)
endif


CONTAINER_NAME := muffin_qemu
PROJECT ?= wiggly

ALPINE_DIR ?= $(BUILD_ROOT)/alpine
UBOOT_DIR ?= $(BUILD_ROOT)/u-boot

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
		-v $(BUILD_ROOT):/build \
		-v $(ALPINE_BUILD):/alpine \
		-v $(UBOOT_BUILD):/u-boot \
		-v $(TFTP_DIST):/tftp \
		-v $(DOWNLOADS_ROOT):/downloads \
		$(CONTAINER_TAG):build \
		qemu-system-aarch64 \
			-d guest_errors \
			-machine virt \
			-cpu cortex-a72 \
			-m 512M \
			-nographic \
			-device virtio-net-device,id=net0dev,netdev=net0 \
			-netdev user,id=net0,tftp=/tftp,bootfile=u-boot.scr \
			-drive file=/alpine/alpine-virt-aarch64-latest-stable.iso,media=cdrom \
			-bios /u-boot/u-boot-qemu_arm64-cortex-a72.bin 

      
build: docker-promote 
	@echo "Stub: Building QEMU disk images..."

clean:
	@echo "Stub: Cleaning QEMU images..."

dist:
	@echo "Stub: Installing QEMU artifacts to dist/..."

