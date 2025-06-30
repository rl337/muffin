.PHONY: all build clean dist qemu run-qemu artifacts

PROJECT ?= wiggly

ifndef PROJECT_ROOT
$(error PROJECT_ROOT is not set. Usage: $(MAKE) PROJECT_ROOT=value)
endif

ifndef SCRATCH_ROOT
$(error SCRATCH_ROOT is not set. Usage: $(MAKE) SCRATCH_ROOT=value)
endif
BUILD_ROOT := $(SCRATCH_ROOT)/build

ifndef DOWNLOADS_ROOT
$(error DOWNLOADS_ROOT is not set. Usage: $(MAKE) DOWNLOADS_ROOT=value)
endif

ifndef DIST_ROOT
$(error DIST_ROOT is not set. Usage: $(MAKE) DIST_ROOT=value)
endif

ifndef DOWNLOADS_ROOT
$(error DOWNLOADS_ROOT is not set. Usage: $(MAKE) DOWNLOADS_ROOT=value)
endif

ifndef TFTP_SERVER_IP
$(error TFTP_SERVER_IP is not set. Usage: $(MAKE) TFTP_SERVER_IP=value)
endif

ifndef HTTP_SERVER_IP
$(error HTTP_SERVER_IP is not set. Usage: $(MAKE) HTTP_SERVER_IP=value)
endif


DIST_ROOT := $(SCRATCH_ROOT)/dist
TFTP_DIST := $(DIST_ROOT)/tftp
HTTP_DIST := $(DIST_ROOT)/http
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

$(ARTIFACTS_ROOT):
	mkdir -p $(ARTIFACTS_ROOT)

$(DOWNLOADS_ROOT):
	mkdir -p $(DOWNLOADS_ROOT)

$(TFTP_DIST): $(DIST_ROOT)
	mkdir -p $(TFTP_DIST)

$(HTTP_DIST): $(DIST_ROOT)
	mkdir -p $(HTTP_DIST)

$(NFS_DIST): $(DIST_ROOT)
	mkdir -p $(NFS_DIST)

$(ALPINE_BUILD): $(BUILD_ROOT)
	mkdir -p $(ALPINE_BUILD)

$(RPI_BUILD): $(BUILD_ROOT)
	mkdir -p $(RPI_BUILD)

$(QEMU_BUILD): $(BUILD_ROOT)
	mkdir -p $(QEMU_BUILD)

init: $(ALPINE_BUILD) $(QEMU_BUILD) $(RPI_BUILD) $(DOWNLOADS_ROOT) $(NFS_DIST) $(TFTP_DIST) $(HTTP_DIST) $(ARTIFACTS_ROOT)
	$(MAKE) artifacts

downloads: $(DOWNLOADS_ROOT)

verify-%:
	@if [ -z "$($*)" ]; then \
		echo "$* is not set"; \
		exit 1; \
	fi

artifacts: $(ARTIFACTS_ROOT)
	ansible-playbook -e 'project_root=$(PROJECT_ROOT)' -e 'artifacts_root=$(ARTIFACTS_ROOT)' -i inventory.ini $(PROJECT_ROOT)/ansible/playbooks/main.yml


########################################################
# Alpine - Build alpine appliance images
########################################################

build: init verify-TFTP_SERVER_IP verify-HTTP_SERVER_IP verify-NFS_SERVER_IP
	$(MAKE) -C alpine build \
		PROJECT=$(PROJECT) \
		PROJECT_ROOT=$(PROJECT_ROOT) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		TFTP_SERVER_IP=$(TFTP_SERVER_IP) \
		HTTP_SERVER_IP=$(HTTP_SERVER_IP) \
		ARCH=aarch64 \
		ALPINE_VERSION=$(ALPINE_VERSION) \
		BUILD_ROOT=$(BUILD_ROOT) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT)

	$(MAKE) -C raspberrypi build \
		PROJECT=$(PROJECT) \
		PROJECT_ROOT=$(PROJECT_ROOT) \
		BUILD_ROOT=$(BUILD_ROOT) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT)

clean:
	@echo "Stub: Cleaning build and dist directories..."

dist: init verify-TFTP_SERVER_IP
    
	$(MAKE) -C alpine dist \
		PROJECT=$(PROJECT) \
		PROJECT_ROOT=$(PROJECT_ROOT) \
		TFTP_SERVER_IP=$(TFTP_SERVER_IP) \
		HTTP_SERVER_IP=$(HTTP_SERVER_IP) \
		HARDWARE=rpi \
		ARCH=aarch64 \
		ALPINE_VERSION=$(ALPINE_VERSION) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		TFTP_DIST=$(TFTP_DIST) \
		HTTP_DIST=$(HTTP_DIST) \
		BUILD_ROOT=$(ALPINE_BUILD) \
		ARTIFACTS_ROOT=$(ARTIFACTS_ROOT)
	$(MAKE) -C alpine dist \
		PROJECT=$(PROJECT) \
		PROJECT_ROOT=$(PROJECT_ROOT) \
		TFTP_SERVER_IP=$(TFTP_SERVER_IP) \
		HTTP_SERVER_IP=$(HTTP_SERVER_IP) \
		ARCH=x86_64 \
		HARDWARE=virt \
		ALPINE_VERSION=$(ALPINE_VERSION) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		TFTP_DIST=$(TFTP_DIST) \
		HTTP_DIST=$(HTTP_DIST) \
		BUILD_ROOT=$(ALPINE_BUILD) \
		ARTIFACTS_ROOT=$(ARTIFACTS_ROOT)
	$(MAKE) -C raspberrypi dist \
		PROJECT=$(PROJECT) \
		PROJECT_ROOT=$(PROJECT_ROOT) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT) \
		TFTP_DIST=$(TFTP_DIST) \
		BUILD_ROOT=$(RPI_BUILD)

qemu: init
	$(MAKE) -C qemu build \
		PROJECT=$(PROJECT) \
		PROJECT_ROOT=$(PROJECT_ROOT) \
		BUILD_ROOT=$(BUILD_ROOT) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT)	

run-qemu:
	$(MAKE) -C qemu run \
		PROJECT=$(PROJECT) \
		PROJECT_ROOT=$(PROJECT_ROOT) \
		BUILD_ROOT=$(QEMU_BUILD) \
		ALPINE_BUILD=$(ALPINE_BUILD) \
		TFTP_DIST=$(TFTP_DIST) \
		DOWNLOADS_ROOT=$(DOWNLOADS_ROOT)

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
