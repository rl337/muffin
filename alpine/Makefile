.PHONY: init build clean dist docker-build docker-promote get-latest-images scour

CONTAINER_NAME := muffin_alpine
PROJECT ?= wiggly

BUILD_ROOT ?= $(realpath ../build)
DIST_ROOT ?= $(realpath ../dist)
TFTP_DIST ?= $(DIST_ROOT)/tftp
WORKING_DIR ?= $(BUILD_ROOT)/alpine
DOWNLOAD_DIR ?= $(WORKING_DIR)/downloads

CONTAINER_TAG := $(PROJECT)/$(CONTAINER_NAME)

init:
	mkdir -p $(WORKING_DIR)
	mkdir -p $(DOWNLOAD_DIR)

docker-build:
	docker build -t $(CONTAINER_TAG):latest .

docker-promote: docker-build
	docker tag $(CONTAINER_TAG):latest $(CONTAINER_TAG):build

get-latest-image:
	docker run --rm \
	    -v .:/app \
		-v $(WORKING_DIR):/working \
		-v $(DOWNLOAD_DIR):/downloads \
		$(CONTAINER_TAG):build \
		/bin/sh -c "cd /app && WORKING_DIR=/working DOWNLOAD_DIR=/downloads TYPE='$(TYPE)' TITLE='$(TITLE)' bash ./get-latest.sh"

build: init docker-promote
	@echo "Stub: Building Alpine base images..."

	$(MAKE) get-latest-image TYPE=virt TITLE="Virtual"
	$(MAKE) get-latest-image TYPE=rpi TITLE="Raspberry Pi Disk Image"

	
clean:
	rm -rf $(WORKING_DIR)

scour:
	rm -rf $(DOWNLOAD_DIR)

dist: build
	@echo "Stub: Installing Alpine outputs to dist/..."
	cp $(WORKING_DIR)/$(shell cat $(WORKING_DIR)/virt-meta.txt | grep UNPACK_NAME | cut -f 2 -d=)/boot/vmlinuz-virt \
	    $(TFTP_DIST)/vmlinuz-virt-$(shell cat $(WORKING_DIR)/virt-meta.txt | grep IMAGE_VERSION | cut -f 2 -d=)
	cp $(WORKING_DIR)/$(shell cat $(WORKING_DIR)/virt-meta.txt | grep UNPACK_NAME | cut -f 2 -d=)/boot/initramfs-virt \
	    $(TFTP_DIST)/initramfs-virt-$(shell cat $(WORKING_DIR)/virt-meta.txt | grep IMAGE_VERSION | cut -f 2 -d=)

	cp $(WORKING_DIR)/$(shell cat $(WORKING_DIR)/rpi-meta.txt | grep UNPACK_NAME | cut -f 2 -d=)/vmlinuz-rpi \
	    $(TFTP_DIST)/vmlinuz-rpi-$(shell cat $(WORKING_DIR)/rpi-meta.txt | grep IMAGE_VERSION | cut -f 2 -d=)
	cp $(WORKING_DIR)/$(shell cat $(WORKING_DIR)/rpi-meta.txt | grep UNPACK_NAME | cut -f 2 -d=)/initramfs-rpi \
	    $(TFTP_DIST)/initramfs-rpi-$(shell cat $(WORKING_DIR)/rpi-meta.txt | grep IMAGE_VERSION | cut -f 2 -d=)


