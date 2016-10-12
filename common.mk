DIST ?= jessie
REPO ?= Raspbian
RPI ?= 2
DIST_ARCH ?= armhf
ARCH ?= rpix
UNAME ?= pi
UPASS ?= pi
RPASS ?= pi
LOCALE ?= en_US.UTF-8
IMAGE_MB ?= -1
BOOT_MB ?= 128
INC_REC ?= 0

REPOBASE := Raspbian
REPOS := $(REPO)
RPIV := $(RPI)
BOOT_DIR := boot
UBOOT_DIR := rpi_2

QEMU := qemu-arm-static

ifeq ($(findstring Raspbian,$(REPOS)),Raspbian)
	ifneq ($(findstring Foundation,$(REPOS)),Foundation)
		REPOS += Foundation
	endif
	REPOBASE := Raspbian
	DIST_ARCH := armhf
	ARCH := rpix
else ifeq ($(findstring Bluefalls,$(REPOS)),Bluefalls)
	ifneq ($(findstring Debian,$(REPOS)),Debian)
		REPOS += Debian
	endif
	REPOBASE := Bluefalls
	ifeq ($(DIST_ARCH),armel)
		ARCH := rpi
	else ifeq ($(DIST_ARCH),arm64)
		ARCH := rpi3
	else
		DIST_ARCH := armhf
		ARCH := rpi2
	endif
else ifeq ($(findstring Debian,$(REPOS)),Debian)
	REPOBASE := Debian
	BOOT_DIR := boot/firmware
	ifeq ($(DIST_ARCH),arm64)
		ARCH := arm64
		UBOOT_DIR := rpi_3
	else ifeq ($(DIST_ARCH),armel)
		ARCH := armel
		UBOOT_DIR := rpi
	else
		ifeq ($(RPIV),3)
			UBOOT_DIR := rpi_3_32b
		endif
		DIST_ARCH := armhf
		ifneq ($(findstring armmp,$(ARCH)),armmp)
			ARCH := armmp
		endif
	endif
endif

ifeq ($(DIST_ARCH),arm64)
	QEMU := qemu-aarch64-static
endif

ifeq ($(shell test $(BOOT_MB) -lt 38; echo $$?),0)
	BOOT_MB := 38
endif

ifeq ($(IMAGE_MB),-1)
	ROOT_MB := -1
else
	ROOT_MB := $(shell expr $(IMAGE_MB) - $(BOOT_MB))
endif

TIMESTAMP := $(shell date +'%Y-%m-%dT%H:%M:%S')
ROOT_DEV := /dev/mmcblk0p2
BASE_DIR := $(shell pwd)
ROOTFS_DIR := $(BASE_DIR)/rootfs
IMAGE_FILE := $(REPOBASE)-$(DIST)-$(ARCH)
