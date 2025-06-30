.PHONY: build clean dist docker-build docker-promote fetch-alpine-release-file refresh-apk-mirror verify-type verify-arch verify-alpine-version verify-alpine-release verify-filename verify-destination

CONTAINER_NAME := muffin_alpine
BASE_HTTP_URL := https://dl-cdn.alpinelinux.org/alpine

ifndef PROJECT
$(error PROJECT is not set. Usage: $(MAKE) -C alpine PROJECT=value)
endif

ifndef PROJECT_ROOT
$(error PROJECT_ROOT is not set. Usage: $(MAKE) -C alpine PROJECT_ROOT=value)
endif

CONTAINER_TAG := $(PROJECT)/$(CONTAINER_NAME)

ifndef DOWNLOADS_ROOT
$(error DOWNLOADS_ROOT is not set. Usage: $(MAKE) -C alpine DOWNLOADS_ROOT=value)
endif

ifndef ARTIFACTS_ROOT
$(error ARTIFACTS_ROOT is not set. Usage: $(MAKE) -C alpine ARTIFACTS_ROOT=value)
endif

ifndef ALPINE_VERSION
$(error ALPINE_VERSION is not set. Usage: $(MAKE) -C alpine ALPINE_VERSION=value)
endif

ifndef BUILD_ROOT
$(error BUILD_ROOT is not set. Usage: $(MAKE) -C alpine BUILD_ROOT=value)
endif

ifndef ARCH
$(error ARCH is not set. Usage: $(MAKE) -C alpine ARCH=value)
endif

ifndef HARDWARE
$(error HARDWARE is not set. Usage: $(MAKE) -C alpine HARDWARE=value)
endif

ifndef TFTP_SERVER_IP
$(error TFTP_SERVER_IP is not set. Usage: $(MAKE) -C alpine TFTP_SERVER_IP=value)
endif

ifndef HTTP_SERVER_IP
$(error HTTP_SERVER_IP is not set. Usage: $(MAKE) -C alpine HTTP_SERVER_IP=value)
endif

ifndef HTTP_DIST
$(error HTTP_DIST is not set. Usage: $(MAKE) -C alpine HTTP_DIST=value)
endif

ifndef TFTP_DIST
$(error TFTP_DIST is not set. Usage: $(MAKE) -C alpine TFTP_DIST=value)
endif

APKS_DIRECTORY := $(DOWNLOADS_ROOT)/apks/$(ALPINE_VERSION)/$(ARCH)
APKS_REPOSITORY := $(DOWNLOADS_ROOT)/apks/$(ALPINE_VERSION)/

PLATFORM_linux/aarch64  := linux/arm64
PLATFORM_linux/x86_64   := linux/amd64
PLATFORM := $(PLATFORM_linux/$(ARCH))

APK_PUB_KEY_NAME := $(PROJECT)-apkkey.rsa.pub
APK_PRIV_KEY_NAME := $(PROJECT)-apkkey.rsa
SSH_CA_KEY_NAME := $(PROJECT)-ssh-ca.key

APK_PUB_KEY_FILE := $(ARTIFACTS_ROOT)/$(APK_PUB_KEY_NAME)
APK_PRIV_KEY_FILE := $(ARTIFACTS_ROOT)/$(APK_PRIV_KEY_NAME)
SSH_CA_KEY_FILE := $(ARTIFACTS_ROOT)/$(SSH_CA_KEY_NAME)

BUILD_NAME := $(HARDWARE)-$(ARCH)-$(ALPINE_VERSION)
ANSIBLE_NAME := ansible-$(BUILD_NAME)
CHROOT_NAME := apkovl-$(BUILD_NAME)


SOURCE_ANSIBLE_DIRECTORY := $(PROJECT_ROOT)/alpine/ansible
TARGET_ANSIBLE_DIRECTORY := $(BUILD_ROOT)/$(ANSIBLE_NAME)
CHROOT_PATH := $(BUILD_ROOT)/$(CHROOT_NAME)

docker-build:
	docker build --platform=$(PLATFORM) -t $(CONTAINER_TAG):latest .

docker-promote: docker-build
	docker tag $(CONTAINER_TAG):latest $(CONTAINER_TAG):build


verify-%:
	@if [ -z "$($*)" ]; then \
		echo "$* is not set"; \
		exit 1; \
	fi

$(TARGET_ANSIBLE_DIRECTORY): 
	mkdir -p $(TARGET_ANSIBLE_DIRECTORY)

$(TARGET_ANSIBLE_DIRECTORY)/inventory.ini: $(TARGET_ANSIBLE_DIRECTORY) $(SOURCE_ANSIBLE_DIRECTORY)/inventory.ini.in
	CHROOT_PATH=$(CHROOT_PATH) \
	    envsubst '$$CHROOT_PATH' < $(SOURCE_ANSIBLE_DIRECTORY)/inventory.ini.in > $(TARGET_ANSIBLE_DIRECTORY)/inventory.ini

$(TARGET_ANSIBLE_DIRECTORY)/playbooks: $(TARGET_ANSIBLE_DIRECTORY) $(TARGET_ANSIBLE_DIRECTORY)/inventory.ini
	cp -r $(SOURCE_ANSIBLE_DIRECTORY)/playbooks $(TARGET_ANSIBLE_DIRECTORY)/

fetch-alpine-release-file: docker-promote verify-ALPINE_RELEASE verify-ARCH verify-ALPINE_VERSION verify-FILENAME verify-DESTINATION_DIR verify-DESTINATION_FILE
	@echo "Downloading Alpine $(ALPINE_RELEASE) file $(FILENAME)..."
	docker run --platform=$(PLATFORM) --rm \
		-v $(DESTINATION_DIR):$(DESTINATION_DIR) \
		$(CONTAINER_TAG):build \
		/bin/sh -c "wget $(BASE_HTTP_URL)/$(ALPINE_VERSION)/releases/$(ARCH)/$(ALPINE_RELEASE)/$(FILENAME) -O $(DESTINATION_DIR)/$(DESTINATION_FILE)"

$(APK_PUB_KEY_FILE):
	docker run --platform=$(PLATFORM) --rm \
		-v $(ARTIFACTS_ROOT):$(ARTIFACTS_ROOT) \
		$(CONTAINER_TAG):build \
		/bin/sh -cx "abuild-keygen -a -n && cp /root/.abuild/-*.rsa.pub $(APK_PUB_KEY_FILE) && cp /root/.abuild/-*.rsa $(APK_PRIV_KEY_FILE)"

$(SSH_CA_KEY_FILE):
	docker run --platform=$(PLATFORM) --rm \
		-v $(ARTIFACTS_ROOT):/build \
		$(CONTAINER_TAG):build \
		/bin/sh -cx "ssh-keygen -t rsa -b 4096 -f /build/$(SSH_CA_KEY_NAME) -N ''"

refresh-apk-mirror: docker-promote verify-ARCH verify-ALPINE_VERSION $(APK_PUB_KEY_FILE)
	mkdir -p $(APKS_DIRECTORY) && \
	docker run --platform=$(PLATFORM) --rm \
		-v $(APKS_REPOSITORY):$(APKS_REPOSITORY) \
		-v $(BUILD_ROOT):$(BUILD_ROOT) \
		-v $(ARTIFACTS_ROOT):$(ARTIFACTS_ROOT) \
		-v $(PROJECT_ROOT):$(PROJECT_ROOT) \
		$(CONTAINER_TAG):build \
		/bin/sh -cx "mkdir -p /tmp/simulation-root/etc/ && \
			cp -r /etc/apk /tmp/simulation-root/etc && \
			apk --root=/tmp/simulation-root add --initdb && \
			apk --root=/tmp/simulation-root update && \
		    apk --root=/tmp/simulation-root --simulate add $$(cat required_packages.txt | tr '\n' ' ') | \
			    grep -v 'OK' | cut -f3 -d\  > $(BUILD_ROOT)/full-package-list-$(ARCH).txt && \
			apk --root=/tmp/simulation-root fetch --recursive --output $(APKS_REPOSITORY)/$(ARCH) \`cat $(BUILD_ROOT)/full-package-list-$(ARCH).txt | tr '\n' ' '\` && \
			apk index --rewrite-arch $(ARCH) -o $(APKS_REPOSITORY)/$(ARCH)/APKINDEX.tar.gz $(APKS_REPOSITORY)/$(ARCH)/*.apk && \
			abuild-sign -k $(APK_PRIV_KEY_FILE) $(APKS_REPOSITORY)/$(ARCH)/APKINDEX.tar.gz"

$(BUILD_ROOT)/apkovl-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION).tar.gz: refresh-apk-mirror $(SSH_CA_KEY_FILE) $(TARGET_ANSIBLE_DIRECTORY)/playbooks
		mkdir -p $(CHROOT_PATH); \
		mkdir -p $(CHROOT_PATH)/etc/apk/keys; \
		cp $(APK_PUB_KEY_FILE) $(CHROOT_PATH)/etc/apk/keys/ && \
		docker run --platform=$(PLATFORM) --rm \
			-v $(BUILD_ROOT):$(BUILD_ROOT) \
			-v $(APKS_REPOSITORY):$(APKS_REPOSITORY) \
			--cap-add=SYS_CHROOT -u root \
			$(CONTAINER_TAG):build \
			/bin/sh -cx "\
				apk --root $(CHROOT_PATH) --repository $(APKS_REPOSITORY) --initdb add $$(cat required_packages.txt | tr '\n' ' ') && \
				ansible-playbook -e 'project_root=$(PROJECT_ROOT)' -e 'artifacts_root=$(ARTIFACTS_ROOT)' -i $(TARGET_ANSIBLE_DIRECTORY)/inventory.ini $(TARGET_ANSIBLE_DIRECTORY)/playbooks/main.yml && \
				tar -czf $(CHROOT_PATH).tar.gz -C $(CHROOT_PATH) ."

$(DOWNLOADS_ROOT)/%-$(ARCH)-$(ALPINE_VERSION): 
	$(MAKE) verify-ARCH 
	$(MAKE) verify-ALPINE_VERSION 
	$(MAKE) fetch-alpine-release-file \
		ALPINE_RELEASE=netboot \
		FILENAME=$* \
		DESTINATION_DIR=$(DOWNLOADS_ROOT) \
		DESTINATION_FILE=$(@F)

$(BUILD_ROOT)/cmdline.txt: cmdline.txt.in
	$(MAKE) verify-ARCH 
	$(MAKE) verify-ALPINE_VERSION 
	ALPINE_REPO_URL="http://$(HTTP_SERVER_IP)/apks/$(ALPINE_VERSION)" \
		MODLOOP_URL="http://$(HTTP_SERVER_IP)/modloop-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION)" \
		NOCLOUD_CONFIG_URL="http://$(HTTP_SERVER_IP)/configs" \
		APKOVL_URL="http://$(HTTP_SERVER_IP)/apkovl-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION).tar.gz" \
		envsubst '$$ALPINE_REPO_URL $$MODLOOP_URL $$NOCLOUD_CONFIG_URL $$APKOVL_URL' < ./cmdline.txt.in > $(BUILD_ROOT)/cmdline.txt

$(BUILD_ROOT)/config.txt: cmdline.txt.in
	$(MAKE) verify-ARCH 
	$(MAKE) verify-ALPINE_VERSION 
	KERNEL_FILE=vmlinuz-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) \
		INITRAMFS_FILE=initramfs-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) \
		envsubst '$$KERNEL_FILE $$INITRAMFS_FILE' < ./config.txt.in > $(BUILD_ROOT)/config.txt


build: $(BUILD_ROOT)/apkovl-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION).tar.gz \
	$(DOWNLOADS_ROOT)/vmlinuz-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) \
	$(DOWNLOADS_ROOT)/initramfs-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) \
	$(DOWNLOADS_ROOT)/modloop-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) \
	$(BUILD_ROOT)/cmdline.txt \
	$(BUILD_ROOT)/config.txt

clean:
	@echo "Stub: Cleaning Alpine base images..."

dist: build
	if [ "$(HARDWARE)" == "rpi" ]; then \
		cp $(BUILD_ROOT)/cmdline.txt $(TFTP_DIST)/; \
		cp $(BUILD_ROOT)/config.txt $(TFTP_DIST)/; \
	fi

	cp $(BUILD_ROOT)/apkovl-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION).tar.gz $(TFTP_DIST)/
	cp $(DOWNLOADS_ROOT)/vmlinuz-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) $(TFTP_DIST)/
	cp $(DOWNLOADS_ROOT)/initramfs-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) $(TFTP_DIST)/
	cp $(DOWNLOADS_ROOT)/modloop-$(HARDWARE)-$(ARCH)-$(ALPINE_VERSION) $(TFTP_DIST)/

	rsync -avz $(APKS_DIRECTORY)/ $(HTTP_DIST)/apks/$(ALPINE_VERSION)/$(ARCH)/