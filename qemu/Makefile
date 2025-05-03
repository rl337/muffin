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
	for thisconfig in $(DTB_CONFIGS); do \
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
	  docker run --rm \
	    -v $(BUILD_ROOT):/build \
	    $(CONTAINER_TAG):build \
	    dtc -I dtb -O dts \
	      -o /build/qemu/virt-$${cpu}-$${cores}cpu-$${mem}-qemu.dts \
		  /build/qemu/virt-$${cpu}-$${cores}cpu-$${mem}-qemu.dtb; \
	  cat $(WORKING_DIR)/virt-$${cpu}-$${cores}cpu-$${mem}-qemu.dts | \
		sed -e 's/ 0x9000000 / 0x09000000 /g' | \
		sed -e 's/ 0x9010000 / 0x09010000 /g' | \
		sed -e 's/ 0x9030000 / 0x09030000 /g' > \
			$(WORKING_DIR)/virt-$${cpu}-$${cores}cpu-$${mem}-qemu-fixed.dts; \
	  docker run --rm \
	    -v $(BUILD_ROOT):/build \
	    $(CONTAINER_TAG):build \
	    dtc -I dts -O dtb -o /build/qemu/virt-$${cpu}-$${cores}cpu-$${mem}-dtc.dtb \
	      /build/qemu/virt-$${cpu}-$${cores}cpu-$${mem}-qemu-fixed.dts; \
	done


create-qcow2:
	docker run --rm \
		-v $(WORKING_DIR):/build \
		$(CONTAINER_TAG):build \
		qemu-img create -f qcow2 /build/virt-hd0.qcow2 2G

run: docker-promote create-qcow2
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
			-cdrom /alpine/downloads/alpine-virt-3.21.3-aarch64.iso \
			-netdev user,id=net0,tftp=/tftp,bootfile=u-boot.scr \
			-drive file=/build/virt-hd0.qcow2,media=disk,format=qcow2 \
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
