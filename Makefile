.PHONY: all build clean dist u-boot alpine qemu

PROJECT ?= wiggly

all: build

build: u-boot alpine qemu

clean:
	$(MAKE) -C u-boot clean PROJECT=$(PROJECT)
	$(MAKE) -C alpine clean PROJECT=$(PROJECT)
	$(MAKE) -C qemu clean PROJECT=$(PROJECT)

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
