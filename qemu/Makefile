.PHONY: build clean dist docker-build docker-promote

BUILD_ROOT ?= $(realpath ../build)
DIST_ROOT ?= $(realpath ../dist)

CONTAINER_NAME := muffin_qemu
PROJECT ?= wiggly
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
	      -machine dumpdtb=/build/qemu/virt-$${cpu}-$${cores}cpu-$${mem}.dtb; \
	done


build: docker-promote build-matrix
	@echo "Stub: Building QEMU disk images..."

clean:
	@echo "Stub: Cleaning QEMU images..."
	rm -rf $(BUILD_ROOT)/qemu
	rm -rf $(DIST_ROOT)/qemu

dist:
	@echo "Stub: Installing QEMU artifacts to dist/..."
	mkdir -p $(DIST_ROOT)/qemu
	cp $(BUILD_ROOT)/qemu/*.dtb $(DIST_ROOT)/qemu/
