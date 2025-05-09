.PHONY: all build clean dist u-boot alpine qemu u-boot-build-scr run-qemu downloads create-qcow2

PROJECT ?= wiggly
PROJECT_ROOT ?= $(realpath .)
SCRATCH_ROOT ?= $(PROJECT_ROOT)/scratch
BUILD_ROOT ?= $(SCRATCH_ROOT)/build
DIST_ROOT ?= $(SCRATCH_ROOT)/dist
DOWNLOADS_ROOT ?= $(SCRATCH_ROOT)/downloads

TFTP_DIST := $(DIST_ROOT)/tftp
NFS_DIST := $(DIST_ROOT)/nfs

UBOOT_BUILD := $(BUILD_ROOT)/u-boot
ALPINE_BUILD := $(BUILD_ROOT)/alpine
QEMU_BUILD := $(BUILD_ROOT)/qemu

UBOOT_BUILD_MATRIX := \
	qemu_arm64:cortex-a72 
#	qemu_arm64:cortex-a76 \
#	rpi_4:cortex-a72 \
#	rpi_arm64:cortex-a76 \

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

$(UBOOT_BUILD): $(BUILD_ROOT)
	mkdir -p $(UBOOT_BUILD)

$(ALPINE_BUILD): $(BUILD_ROOT)
	mkdir -p $(ALPINE_BUILD)

$(QEMU_BUILD): $(BUILD_ROOT)
	mkdir -p $(QEMU_BUILD)

init: $(UBOOT_BUILD) $(ALPINE_BUILD) $(QEMU_BUILD) $(DOWNLOADS_ROOT) $(NFS_DIST) $(TFTP_DIST)

downloads: $(DOWNLOADS_ROOT)


$(UBOOT_BUILD)/u-boot-qemu_arm64-cortex-a72.bin: $(UBOOT_BUILD)
	$(MAKE) -C u-boot build PROJECT=$(PROJECT) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) BUILD_ROOT=$(UBOOT_BUILD) UBOOT_CONF=qemu_arm64 CPU=cortex-a72

$(ALPINE_BUILD)/vmlinuz-rpi-aarch64-latest-stable: $(ALPINE_BUILD)
	$(MAKE) -C alpine build PROJECT=$(PROJECT) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) BUILD_ROOT=$(ALPINE_BUILD) ALPINE_VERSION=latest-stable ARCH=aarch64 TYPE=rpi TITLE="Raspberry Pi Disk Image"

$(ALPINE_BUILD)/vmlinuz-virt-aarch64-latest-stable: $(ALPINE_BUILD)
	$(MAKE) -C alpine build PROJECT=$(PROJECT) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) BUILD_ROOT=$(ALPINE_BUILD) ALPINE_VERSION=latest-stable ARCH=aarch64 TYPE=virt TITLE="Virtual"

$(ALPINE_BUILD)/vmlinuz-virt-x86_64-latest-stable: $(ALPINE_BUILD)
	$(MAKE) -C alpine build PROJECT=$(PROJECT) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) BUILD_ROOT=$(ALPINE_BUILD) ALPINE_VERSION=latest-stable ARCH=x86_64 TYPE=virt TITLE="Virtual"


build-u-boot: $(UBOOT_BUILD)/u-boot-qemu_arm64-cortex-a72.bin
build-alpine: $(ALPINE_BUILD)/vmlinuz-rpi-aarch64-latest-stable $(ALPINE_BUILD)/vmlinuz-virt-aarch64-latest-stable $(ALPINE_BUILD)/vmlinuz-virt-x86_64-latest-stable

build-libguestfs: 
	$(MAKE) -C libguestfs build PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT)

build: build-u-boot build-alpine build-libguestfs


clean:
	$(MAKE) -C u-boot clean PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DIST_ROOT=$(DIST_ROOT) UBOOT_REPO=$(UBOOT_REPO)
	$(MAKE) -C alpine clean PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DIST_ROOT=$(DIST_ROOT)
	$(MAKE) -C qemu clean PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DIST_ROOT=$(DIST_ROOT)
	if [ -d $(BUILD_ROOT) ]; then \
		rmdir $(BUILD_ROOT) 2>/dev/null || (echo "ERROR: $(BUILD_ROOT) not empty after clean" && exit 1) \
	fi
	if [ -d $(DIST_ROOT) ]; then \
		rmdir $(DIST_ROOT) 2>/dev/null || (echo "ERROR: $(DIST_ROOT) not empty after clean" && exit 1) \
	fi

dist: init
	$(MAKE) -C u-boot dist PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DIST_ROOT=$(DIST_ROOT) UBOOT_REPO=$(UBOOT_REPO)
	$(MAKE) -C alpine dist PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DIST_ROOT=$(DIST_ROOT)
	$(MAKE) -C qemu dist PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DIST_ROOT=$(DIST_ROOT)

u-boot: init
	$(MAKE) -C u-boot build PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DIST_ROOT=$(DIST_ROOT) UBOOT_REPO=$(UBOOT_REPO)

alpine: init
	$(MAKE) -C alpine build PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DIST_ROOT=$(DIST_ROOT)

alpine-dist: init
	$(MAKE) -C alpine dist PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DIST_ROOT=$(DIST_ROOT)

qemu: init
	$(MAKE) -C qemu build PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DIST_ROOT=$(DIST_ROOT)	

u-boot-build-scr: init
	$(MAKE) -C u-boot build-scr PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DIST_ROOT=$(DIST_ROOT)

run-qemu: dist
	$(MAKE) -C qemu run PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DIST_ROOT=$(DIST_ROOT) TFTP_DIST=$(TFTP_DIST)

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