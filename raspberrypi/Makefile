.PHONY: build clean dist docker-build docker-promote

ifndef PROJECT
$(error PROJECT is not set. Usage: $(MAKE) -C libguestfs PROJECT=value)
endif

ifndef DOWNLOADS_ROOT
$(error DOWNLOADS_ROOT is not set. Usage: $(MAKE) -C libguestfs DOWNLOADS_ROOT=value)
endif

ifndef TFTP_DIST
	$(error TFTP_DIST is not set. Usage: $(MAKE) -C raspberrypi TFTP_DIST=value)
endif

CONTAINER_NAME := muffin_raspberrypi
CONTAINER_TAG := $(PROJECT)/$(CONTAINER_NAME)
FIRMWARE_CHECKOUT_DIR := $(DOWNLOADS_ROOT)/firmware
FIRMWARE_REPO_URL := https://github.com/raspberrypi/firmware/archive/refs/heads

FIRMWARE_VERSION := 'stable'


$(FIRMWARE_CHECKOUT_DIR):
	docker run --rm \
		-v $(DOWNLOADS_ROOT):/checkout \
		$(CONTAINER_TAG):build \
		/bin/sh -c "\
			cd /checkout && \
			if [ ! -d firmware ]; then \
			    wget $(FIRMWARE_REPO_URL)/$(FIRMWARE_VERSION).tar.gz -O firmware.tar.gz && \
				tar -xzf firmware.tar.gz && \
				mv firmware-$(FIRMWARE_VERSION) firmware && \
				rm firmware.tar.gz; \
			else \
				echo 'Raspberry Pi Firmware source already exists, skipping clone.'; \
			fi"


$(TFTP_DIST)/%: $(FIRMWARE_CHECKOUT_DIR)
	cp $(FIRMWARE_CHECKOUT_DIR)/boot/$* $(TFTP_DIST)/

docker-build:
	docker build -t $(CONTAINER_TAG):latest .

docker-promote: docker-build
	docker tag $(CONTAINER_TAG):latest $(CONTAINER_TAG):build

build: docker-promote $(FIRMWARE_CHECKOUT_DIR)

dist: docker-build build \
	${TFTP_DIST}/bcm2711-rpi-4-b.dtb \
	${TFTP_DIST}/start4.elf \
	${TFTP_DIST}/fixup4.dat \
	${TFTP_DIST}/bcm2712-rpi-5-b.dtb