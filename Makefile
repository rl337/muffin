.PHONY: all build clean dist u-boot alpine qemu

PROJECT ?= wiggly
BUILD_DIR := build
DIST_DIR := dist

all: build

init:
	mkdir -p $(BUILD_DIR) $(DIST_DIR)

build: init u-boot alpine qemu

clean:
	$(MAKE) -C u-boot clean PROJECT=$(PROJECT)
	$(MAKE) -C alpine clean PROJECT=$(PROJECT)
	$(MAKE) -C qemu clean PROJECT=$(PROJECT)
	@rmdir $(BUILD_DIR) 2>/dev/null || (echo "ERROR: $(BUILD_DIR) not empty after clean" && exit 1)
	@rmdir $(DIST_DIR) 2>/dev/null || (echo "ERROR: $(DIST_DIR) not empty after clean" && exit 1)

dist:
	$(MAKE) -C u-boot dist PROJECT=$(PROJECT)
	$(MAKE) -C alpine dist PROJECT=$(PROJECT)
	$(MAKE) -C qemu dist PROJECT=$(PROJECT)

u-boot:
	$(MAKE) -C u-boot build PROJECT=$(PROJECT)

alpine:
	$(MAKE) -C alpine build PROJECT=$(PROJECT)

qemu:
	$(MAKE) -C qemu build PROJECT=$(PROJECT)
