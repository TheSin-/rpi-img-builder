rpi-img-builder
===============

Script to build a minimal Debian sd card image for RPi and RPi2.

## Features:
* Debian repository (Tested with Jessie so far)
* Custom RPi repository
* Custom repositories
* Architectures
* Login: pi/pi
* Auto size, make as compact as possible or set a size
* Plugins

## Plugins
* Host name: raspberrypi-MACADDRESS (e.g. raspberrypi-1a2b3c4d5e6f)
* SSH host keys are generated and saved permanently on first boot
* Run configdb-common scripts on first boot
* Automatic mounting of USB storage devices using usbmount
* Automatic resize on first boot (It will auto reboot once done)
* Automaticly reruns dbconfig install scripts on boot (It will auto reboot once done)

## Options
The build process has a few options you can set.
* **DIST**: debian distribution [Default jessie]
* **DIST_ARCH**: image architecture [armel (rpi), armhf (rpi2, default)]
* **REPOSITORIES**: upstream repositories based on repos dir [Debian Bluefalls (default)]
* **IMAGE_MB**: size of the image, 32MB is for the fat boot, which is included in this option (-1 default which is auto and will leave 20MB on the rootfs free)
* **LOCALE**: system locale (Default en_US.UTF-8) `Make sure you type this exactly like in /usr/share/i18n/SUPPORTED`
* **UNAME**: user account that gets created (Default pi)
* **UPASS**: user account password (Default pi)
* **RPASS**: root password (Default pi)

## Prerequisites:
On a x86 based Debian system, make sure the following packages are installed:
```
sudo apt-get install build-essential wget git lzop u-boot-tools binfmt-support \
                     qemu qemu-user-static multistrap parted dosfstools
```

## Example: Build an RPi2 Jessie image with a forced size of 1G:
Just use the make utility to build e.g. an debian-jessie-rpi2.img.  Be sure to run this with sudo, as root privileges are required to mount the image.
```
sudo make distclean && sudo make DIST=jessie DIST_ARCH=armhf IMAGE_MB=1024
```

This will install the firmware, compile the kernel, bootstrap Debian and create a 1024MB img file, which then can be transferred to a sd card (e.g. using dd):
```
sudo dd bs=1M if=debian-jessie-rpi2.img of=/dev/YOUR_SD_CARD && sudo sync
```

## Customize your image:
It should be fairly easy to customize your image for your own needs.  Bulding and adding plugins is easy.  Each plugin can contain:
* **packages**: file with one line containing debian packages to install
* **preinst**: script to run pre chroot
* **postinst**: script to run in chroot of the rootfs
* **files**: dir which conatins files to be copied into the rootfs, perms and atts included
* **patches**: dir which contains patch files to apply to the rootfs

This should allow you install extra packages (e.g. using apt-get) and modify configurations to your needs.  Of course, you can do all this manually after booting the device, but the goal of this project is to be able to generate re-usable images that can be deployed on any number of RaspberryPi devices (think of it as "firmware" of a consumer device).  The `extrapackages` plugin is an example of a plugin to just add new packages, you can modify it or create a new plugin of your own.

## Notes
There are lots of plugin examples included, you can add and remove to your needs.  There are only there to show how customizable these build scripts are.
