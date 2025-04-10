.PHONY: all build clean dist u-boot alpine qemu

all: build

build: u-boot alpine qemu

clean:
	$(MAKE) -C u-boot clean
	$(MAKE) -C alpine clean
	$(MAKE) -C qemu clean

dist:
	$(MAKE) -C u-boot dist
	$(MAKE) -C alpine dist
	$(MAKE) -C qemu dist

u-boot:
	$(MAKE) -C u-boot build

alpine:
	$(MAKE) -C alpine build

qemu:
	$(MAKE) -C qemu build
