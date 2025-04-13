.PHONY: all build clean dist u-boot alpine qemu

PROJECT ?= wiggly
SCRATCH_ROOT ?= $(realpath ./scratch)
BUILD_ROOT ?= $(SCRATCH_ROOT)/build
DIST_ROOT ?= $(SCRATCH_ROOT)/dist
UBOOT_REPO ?= https://source.denx.de/u-boot/u-boot.git


all: build

$(BUILD_ROOT):
	mkdir -p $(BUILD_ROOT)

$(DIST_ROOT):
	mkdir -p $(DIST_ROOT)

init: $(BUILD_ROOT) $(DIST_ROOT)

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

qemu: init
	$(MAKE) -C qemu build PROJECT=$(PROJECT) BUILD_ROOT=$(BUILD_ROOT) DIST_ROOT=$(DIST_ROOT)	
