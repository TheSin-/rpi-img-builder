DIST ?= jessie
DISTS ?= Debian Bluefalls
DIST_ARCH ?= armhf
ifeq ($(findstring armel,$(DIST_ARCH)),armel)
	ARCH := rpi
else ifeq ($(findstring arm64,$(DIST_ARCH)),arm64)
	ARCH := rpi3
else
	ARCH := rpi2
endif

U-BOOT ?= false

ifeq ($(findstring true,$(U-BOOT)),true)
	ARCH := rpi2
	DIST_ARCH := armhf
	ifneq ($(findstring Debian,$(DISTS)),Debian)
		DISTS += Debian
	endif
endif

ROOT_DEV := /dev/mmcblk0p2

UNAME ?= pi
UPASS ?= pi
RPASS ?= pi

LOCALE ?= en_US.UTF-8

IMAGE_MB ?= -1
BOOT_MB ?= 38
ifeq ($(shell test $(BOOT_MB) -lt 38; echo $$?),0)
	BOOT_MB := 38
endif
ifeq ($(IMAGE_MB),-1)
	ROOT_MB := -1
else
	ROOT_MB=$(shell expr $(IMAGE_MB) - $(BOOT_MB))
endif

BOOT_DIR := boot
ROOTFS_DIR := rootfs
IMAGE_FILE := debian-$(DIST)-$(ARCH).img
