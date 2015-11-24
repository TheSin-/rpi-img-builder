DIST ?= jessie
DIST_URL := http://http.debian.net/debian/
DIST_ARCH ?= armhf
ifeq ($(findstring $(DIST_ARCH),armhf),)
  ARCH := rpi
else
  ARCH := rpi2
endif

ROOT_DEV := /dev/mmcblk0p2

USER ?= pi
PASS ?= pi
ROOTPASS ?= pi

IMAGE_MB ?= 640
BOOT_MB ?= 32
ROOT_MB=$(shell expr $(IMAGE_MB) - $(BOOT_MB))

BOOT_DIR := boot
ROOTFS_DIR := rootfs
IMAGE_FILE := debian-$(DIST)-$(ARCH).img

