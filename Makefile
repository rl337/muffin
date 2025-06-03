.PHONY: all build clean dist u-boot alpine qemu u-boot-build-scr run-qemu downloads create-qcow2 build-u-boot build-alpine

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


verify-server-ip:
	@if [ -z "$(SERVER_IP)" ]; then \
		echo "SERVER_IP is not set"; \
		exit 1; \
	fi

########################################################
# U-Boot - Build U-Boot images
########################################################	

$(UBOOT_BUILD)/u-boot-qemu_arm64-cortex-a72.bin: verify-server-ip $(UBOOT_BUILD) $(UBOOT_BUILD)/u-boot-qemu_arm64-cortex-a72.scr
	$(MAKE) -C u-boot build PROJECT=$(PROJECT) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		BUILD_ROOT=$(UBOOT_BUILD) \
		UBOOT_CONF=qemu_arm64 \
		CPU=cortex-a72 \
		TRANSFER_COMMAND="tftpboot" \
		SCRIPT_ADDR=0x40400000 \
		UBOOT_SCRIPT=u-boot-qemu_arm64-cortex-a72.scr \
		SERVER_IP=$(SERVER_IP)

$(UBOOT_BUILD)/u-boot-rpi_4-cortex-a72.bin: verify-server-ip $(UBOOT_BUILD) $(UBOOT_BUILD)/u-boot-rpi_4-cortex-a72.scr
	$(MAKE) -C u-boot build PROJECT=$(PROJECT) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		BUILD_ROOT=$(UBOOT_BUILD) \
		UBOOT_CONF=rpi_4 \
		CPU=cortex-a72 \
		TRANSFER_COMMAND="tftpboot" \
		SCRIPT_ADDR=0x00080000 \
		UBOOT_SCRIPT=u-boot-rpi_4-cortex-a72.scr \
		SERVER_IP=$(SERVER_IP)

########################################################
# U-Boot - Build U-Boot script
########################################################

$(UBOOT_BUILD)/u-boot-qemu_arm64-cortex-a72.scr: $(UBOOT_BUILD)
	$(MAKE) -C u-boot build-scr PROJECT=$(PROJECT) BUILD_ROOT=$(UBOOT_BUILD) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		BOOTARGS="console=ttyAMA0 earlycon overlaytmpfs=yes debug verbose" \
		UBOOT_SCRIPT=u-boot-qemu_arm64-cortex-a72.scr \
		KERNEL_IMAGE=vmlinuz-virt-aarch64-latest-stable \
		KERNEL_ADDR=0x40200000 \
		INITRD_ADDR=0x42D00000 \
		INITRD_IMAGE=initramfs-virt-aarch64-latest-stable \
		INITRD_SIZE=90186757 

$(UBOOT_BUILD)/u-boot-rpi_4-cortex-a72.scr: $(UBOOT_BUILD)
	$(MAKE) -C u-boot build-scr PROJECT=$(PROJECT) BUILD_ROOT=$(UBOOT_BUILD) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		BOOTARGS="console=ttyAMA0,115200 earlycon=pl011,0xfe201000 overlaytmpfs=yes root=/dev/ram0 debug ignore_loglevel loglevel=8" \
		UBOOT_SCRIPT=u-boot-rpi_4-cortex-a72.scr \
		KERNEL_IMAGE=vmlinuz-rpi \
		KERNEL_ADDR=0x08000000 \
		INITRD_ADDR=0x20000000 \
		INITRD_IMAGE=initramfs-rpi  \
		INITRD_SIZE=6095352

########################################################
# Alpine - Build alpine appliance images
########################################################

$(ALPINE_BUILD)/vmlinuz-rpi-aarch64-latest-stable: verify-server-ip $(ALPINE_BUILD)
	$(MAKE) -C alpine build PROJECT=$(PROJECT) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		BUILD_ROOT=$(ALPINE_BUILD) \
		BASE_HTTP_URL=http://$(SERVER_IP) \
		ALPINE_VERSION=latest-stable \
		ARCH=aarch64 \
		TYPE=rpi \
		TITLE="Raspberry Pi Disk Image"

$(ALPINE_BUILD)/vmlinuz-uboot-aarch64-latest-stable: verify-server-ip $(ALPINE_BUILD)
	$(MAKE) -C alpine build PROJECT=$(PROJECT) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		BUILD_ROOT=$(ALPINE_BUILD) \
		BASE_HTTP_URL=http://$(SERVER_IP) \
		ALPINE_VERSION=latest-stable \
		ARCH=aarch64 \
		TYPE=uboot \
		TITLE="Generic U-Boot"

$(ALPINE_BUILD)/vmlinuz-virt-aarch64-latest-stable: verify-server-ip $(ALPINE_BUILD)
	$(MAKE) -C alpine build PROJECT=$(PROJECT) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		BUILD_ROOT=$(ALPINE_BUILD) \
		BASE_HTTP_URL=http://$(SERVER_IP) \
		ALPINE_VERSION=latest-stable \
		ARCH=aarch64 \
		TYPE=virt \
		TITLE="Virtual"

$(ALPINE_BUILD)/vmlinuz-virt-x86_64-latest-stable: $(ALPINE_BUILD)
	$(MAKE) -C alpine build PROJECT=$(PROJECT) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		BUILD_ROOT=$(ALPINE_BUILD) \
		BASE_HTTP_URL=http://$(SERVER_IP) \
		ALPINE_VERSION=latest-stable \
		ARCH=x86_64 \
		TYPE=virt \
		TITLE="Virtual"

build-u-boot: \
	$(UBOOT_BUILD)/u-boot-qemu_arm64-cortex-a72.bin \
	$(UBOOT_BUILD)/u-boot-rpi_4-cortex-a72.bin

build-alpine: \
    $(ALPINE_BUILD)/vmlinuz-rpi-aarch64-latest-stable \
    $(ALPINE_BUILD)/vmlinuz-virt-aarch64-latest-stable \
    $(ALPINE_BUILD)/vmlinuz-virt-x86_64-latest-stable \
    $(ALPINE_BUILD)/vmlinuz-uboot-aarch64-latest-stable

build: build-u-boot build-alpine

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

alpine: build-alpine

alpine-dist: init
	$(MAKE) -C alpine dist PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DIST_ROOT=$(DIST_ROOT)

qemu: init
	$(MAKE) -C qemu build PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT)	

u-boot-build-scr: $(UBOOT_BUILD)/u-boot-rpi_4-cortex-a72.scr $(UBOOT_BUILD)/u-boot-qemu_arm64-cortex-a72.scr
	

run-qemu:
	$(MAKE) -C qemu run PROJECT=$(PROJECT) BUILD_ROOT=$(QEMU_BUILD) ALPINE_BUILD=$(ALPINE_BUILD) UBOOT_BUILD=$(UBOOT_BUILD) TFTP_DIST=$(TFTP_DIST) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT)

run-qemu-rpi:
	$(MAKE) -C qemu run-rpi PROJECT=$(PROJECT) BUILD_ROOT=$(QEMU_BUILD) ALPINE_BUILD=$(ALPINE_BUILD) UBOOT_BUILD=$(UBOOT_BUILD) TFTP_DIST=$(TFTP_DIST) DOWNLOADS_ROOT=$(DOWNLOADS_ROOT)

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
