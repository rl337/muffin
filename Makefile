.PHONY: all build clean dist u-boot alpine qemu u-boot-build-scr run-qemu

PROJECT ?= wiggly
PROJECT_ROOT ?= $(realpath .)
SCRATCH_ROOT ?= $(PROJECT_ROOT)/scratch
BUILD_ROOT ?= $(SCRATCH_ROOT)/build
DIST_ROOT ?= $(SCRATCH_ROOT)/dist
UBOOT_REPO ?= https://source.denx.de/u-boot/u-boot.git


TFTP_DIST := $(DIST_ROOT)/tftp

all: build

$(BUILD_ROOT):
	mkdir -p $(BUILD_ROOT)

$(DIST_ROOT):
	mkdir -p $(DIST_ROOT)

$(TFTP_DIST): $(DIST_ROOT)
	mkdir -p $(TFTP_DIST)

init: $(BUILD_ROOT) $(DIST_ROOT) $(TFTP_DIST)

build: u-boot alpine qemu

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
