.PHONY: build clean dist docker-build docker-promote

BUILD_ROOT ?= $(realpath ../build)
DIST_ROOT ?= $(realpath ../dist)
TFTP_DIST ?= $(DIST_ROOT)/tftp

CONTAINER_NAME := muffin_qemu
PROJECT ?= wiggly

WORKING_DIR := $(BUILD_ROOT)/qemu
ALPINE_DIR := $(BUILD_ROOT)/alpine
UBOOT_DIR := $(BUILD_ROOT)/u-boot
CHECKOUT_DIR := $(WORKING_DIR)/checkout

DTB_CONFIGS := \
  cortex-a72:1:512M \
  cortex-a76:2:2048M

CONTAINER_TAG := $(PROJECT)/$(CONTAINER_NAME)

docker-build:
	docker build -t $(CONTAINER_TAG):latest .

docker-promote: docker-build
	docker tag $(CONTAINER_TAG):latest $(CONTAINER_TAG):build

build-matrix:
	mkdir -p $(BUILD_ROOT)/qemu
	@echo "Generating QEMU DTBs for known-good configs..."
	@for thisconfig in $(DTB_CONFIGS); do \
	  cpu=$$(echo $$thisconfig | cut -d: -f1); \
	  cores=$$(echo $$thisconfig | cut -d: -f2); \
	  mem=$$(echo $$thisconfig | cut -d: -f3); \
	  echo " - virt-$${cpu}-$${cores}cpu-$${mem}.dtb"; \
	  docker run --rm \
	    -v $(BUILD_ROOT):/build \
	    $(CONTAINER_TAG):build \
	    qemu-system-aarch64 \
	      -machine virt \
	      -cpu $$cpu \
	      -smp $$cores \
	      -m $$mem \
	      -device virtio-net-device \
	      -drive if=none,id=hd0,file=/dev/null,format=raw \
	      -device virtio-blk-device,drive=hd0 \
	      -nographic \
	      -kernel /dev/null \
	      -machine dumpdtb=/build/qemu/virt-$${cpu}-$${cores}cpu-$${mem}-qemu.dtb; \
	  RAM_SIZE=0x20000000 \
	  envsubst < ./virt.dts.in > $(WORKING_DIR)/virt-$${cpu}-$${cores}cpu-$${mem}-dtc.dts; \
	  docker run --rm \
	    -v $(BUILD_ROOT):/build \
	    $(CONTAINER_TAG):build \
	    dtc -I dts -O dtb -o /build/qemu/virt-$${cpu}-$${cores}cpu-$${mem}-dtc.dtb \
	      /build/qemu/virt-$${cpu}-$${cores}cpu-$${mem}-dtc.dts; \
	done

run:
	ls -l $(WORKING_DIR)
	docker run -it --rm \
		-v $(WORKING_DIR):/build \
		-v $(ALPINE_DIR):/alpine \
		-v $(UBOOT_DIR):/u-boot \
		-v $(TFTP_DIST):/tftp \
		$(CONTAINER_TAG):build \
		qemu-system-aarch64 \
			-machine virt \
			-cpu cortex-a72 \
			-m 512M \
			-nographic \
			-netdev user,id=net0,tftp=/tftp,bootfile=u-boot.scr \
			-device virtio-net-device,netdev=net0 \
			-bios /u-boot/u-boot-qemu_arm64-cortex-a72.bin 

build: docker-promote build-matrix
	@echo "Stub: Building QEMU disk images..."

clean:
	@echo "Stub: Cleaning QEMU images..."
	rm -rf $(WORKING_DIR)
	rm -rf $(DIST_ROOT)/qemu

dist:
	@echo "Stub: Installing QEMU artifacts to dist/..."
	mkdir -p $(DIST_ROOT)/qemu
	cp $(WORKING_DIR)/*.dtb $(TFTP_DIST)/
