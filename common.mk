DIST ?= jessie
DIST_ARCH ?= armhf
ifeq ($(findstring $(DIST_ARCH),armhf),)
  ARCH := rpi
else
  ARCH := rpi2
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
