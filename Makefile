#
# You need the following packages installed:
#   sudo apt-get install build-essential wget git lzop u-boot-tools binfmt-support qemu qemu-user-static debootstrap parted dosfstools binutils-arm-linux-gnueabihf gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf
#
# If you are running 64 bit Ubuntu, you might need to run the following 
# commands to be able to launch the 32 bit toolchain:
#
#    sudo dpkg --add-architecture i386
#    sudo apt-get update
#    sudo apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1
#
.PHONY: all
all: distclean build

# Build steps
BUILD_STEPS := rootfs

# Prerequesites for each build step
rootfs-pr:

# Build step rule template
define BUILDSTEP_TEMPLATE
.PHONY: build-$(1) clean-$(1) distclean-$(1) $$($(1)-pr)
build-$(1): $(1)-pr
	$$(MAKE) -f $(1).mak build
clean-$(1):
	$$(MAKE) -f $(1).mak clean
distclean-$(1):
	$$(MAKE) -f $(1).mak distclean
endef

$(foreach step,$(BUILD_STEPS),$(eval $(call BUILDSTEP_TEMPLATE,$(step))))

.PHONY: build
build: $(addprefix build-,$(BUILD_STEPS))

.PHONY: clean
clean: $(addprefix clean-,$(BUILD_STEPS))

.PHONY: distclean
distclean: clean $(addprefix distclean-,$(BUILD_STEPS))

