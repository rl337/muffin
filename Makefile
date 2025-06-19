.PHONY: all build clean dist qemu run-qemu 

PROJECT ?= wiggly
PROJECT_ROOT ?= $(realpath .)
SCRATCH_ROOT ?= $(PROJECT_ROOT)/scratch
BUILD_ROOT ?= $(SCRATCH_ROOT)/build
DIST_ROOT ?= $(SCRATCH_ROOT)/dist
DOWNLOADS_ROOT ?= $(SCRATCH_ROOT)/downloads

TFTP_DIST := $(DIST_ROOT)/tftp
NFS_DIST := $(DIST_ROOT)/nfs

ALPINE_BUILD := $(BUILD_ROOT)/alpine
QEMU_BUILD := $(BUILD_ROOT)/qemu
RPI_BUILD := $(BUILD_ROOT)/raspberrypi

ALPINE_VERSION := latest-stable

all: build

$(BUILD_ROOT):
	mkdir -p $(BUILD_ROOT)

$(DIST_ROOT):
	mkdir -p $(DIST_ROOT)

$(DOWNLOADS_ROOT):
	mkdir -p $(DOWNLOADS_ROOT)

$(TFTP_DIST): $(DIST_ROOT)
	mkdir -p $(TFTP_DIST)

$(NFS_DIST): $(DIST_ROOT)
	mkdir -p $(NFS_DIST)

$(ALPINE_BUILD): $(BUILD_ROOT)
	mkdir -p $(ALPINE_BUILD)

$(RPI_BUILD): $(BUILD_ROOT)
	mkdir -p $(RPI_BUILD)

$(QEMU_BUILD): $(BUILD_ROOT)
	mkdir -p $(QEMU_BUILD)

init: $(ALPINE_BUILD) $(QEMU_BUILD) $(RPI_BUILD) $(DOWNLOADS_ROOT) $(NFS_DIST) $(TFTP_DIST)

downloads: $(DOWNLOADS_ROOT)

verify-server-ip:
	@if [ -z "$(SERVER_IP)" ]; then \
		echo "SERVER_IP is not set"; \
		exit 1; \
	fi

########################################################
# Alpine - Build alpine appliance images
########################################################

build: init 
	$(MAKE) -C alpine build PROJECT=$(PROJECT) SERVER_IP=$(SERVER_IP) ARCH=aarch64 ALPINE_VERSION=$(ALPINE_VERSION) BUILD_ROOT=$(BUILD_ROOT) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT)
	$(MAKE) -C raspberrypi build PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT)

clean:
	@echo "Stub: Cleaning build and dist directories..."

dist: init
	$(MAKE) -C alpine dist \
		PROJECT=$(PROJECT) \
		SERVER_IP=$(SERVER_IP) \
		HARDWARE=rpi \
		ARCH=aarch64 \
		ALPINE_VERSION=$(ALPINE_VERSION) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		TFTP_DIST=$(TFTP_DIST) \
		BUILD_ROOT=$(ALPINE_BUILD)
	$(MAKE) -C alpine dist \
		PROJECT=$(PROJECT) \
		SERVER_IP=$(SERVER_IP) \
		ARCH=x86_64 \
		HARDWARE=virt \
		ALPINE_VERSION=$(ALPINE_VERSION) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		TFTP_DIST=$(TFTP_DIST) \
		BUILD_ROOT=$(ALPINE_BUILD)
	$(MAKE) -C raspberrypi dist \
		PROJECT=$(PROJECT) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		TFTP_DIST=$(TFTP_DIST) \
		BUILD_ROOT=$(RPI_BUILD)

qemu: init
	$(MAKE) -C qemu build PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT)	

run-qemu:
	$(MAKE) -C qemu run PROJECT=$(PROJECT) BUILD_ROOT=$(QEMU_BUILD) ALPINE_BUILD=$(ALPINE_BUILD) TFTP_DIST=$(TFTP_DIST) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT)

run-qemu-rpi:
	$(MAKE) -C qemu run-rpi PROJECT=$(PROJECT) BUILD_ROOT=$(QEMU_BUILD) ALPINE_BUILD=$(ALPINE_BUILD) TFTP_DIST=$(TFTP_DIST) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT)

create-qcow2:
	if [ -z "$(TARGET_FILE)" ]; then \
		echo "TARGET_FILE is not set"; \
		exit 1; \
	fi
	if [ -z "$(SIZE)" ]; then \
		echo "SIZE is not set"; \
		exit 1; \
	fi
	$(MAKE) -C qemu create-qcow2 PROJECT=$(PROJECT) TARGET_FILE=$(TARGET_FILE) SIZE=$(SIZE)
