DIST ?= jessie
REPOSITORIES ?= Debian Bluefalls
DIST_ARCH ?= armhf
ARCH ?= 0
UNAME ?= pi
UPASS ?= pi
RPASS ?= pi
LOCALE ?= en_US.UTF-8
IMAGE_MB ?= -1
BOOT_MB ?= 38

REPOBASE := Debian

ifeq ($(ARCH),0)
	ifeq ($(DIST_ARCH),armel)
		ARCH := rpi
	else ifeq ($(DIST_ARCH),arm64)
		ARCH := rpi3
	else
		ARCH := rpi2
	endif
	REPOBASE := Bluefalls
endif

ifeq ($(findstring Debian,$(REPOSITORIES)),)
	REPOS := Debian $(REPOSITORIES)
else
	REPOS := $(REPOSITORIES)
endif

ifeq ($(findstring Raspbian,$(REPOSITORIES)),Raspbian)
	REPOS := Raspbian
	DIST_ARCH := armhf
	REPOBASE := Raspbian
	ARCH := Raspbian
endif

ifeq ($(shell test $(BOOT_MB) -lt 38; echo $$?),0)
	BOOT_MB := 38
endif
ifeq ($(IMAGE_MB),-1)
	ROOT_MB := -1
else
	ROOT_MB := $(shell expr $(IMAGE_MB) - $(BOOT_MB))
endif

ROOT_DEV := /dev/mmcblk0p2
BOOT_DIR := boot
ROOTFS_DIR := rootfs
IMAGE_FILE := $(DIST)-$(ARCH).img
