debian-mini-rpi
===============

Script to build a minimal Debian sd card image.

## Features:
* Supports building Wheezy or Jessie (default) images (specify using the DIST variable)
* Supports building RPi or RPi2 (default) images (specify using the DIST_ARCH variable)
* Logins: pi/pi (root account is locked, see postinst/lockroot)
* Host name: raspberrypi-MACADDRESS (e.g. raspberrypi-1a2b3c4d5e6f)
* SSH host keys are generated and saved permanently on first boot
* Automatic mounting of USB storage devices using usbmount
* Automatic resize on first boot (It will auto reboot once done)
* Automaticly reruns dbconfig install scripts on boot (It will auto reboot once done)

## Prerequisites:
On a x86 based Debian system, make sure the following packages are installed:
```
sudo apt-get install build-essential wget git lzop u-boot-tools binfmt-support \
                     qemu qemu-user-static multistrap parted dosfstools
```

## Options
The build process has a few options you can set.
* **DIST**: debian distribution [wheezy, jessie (default), etc]
* **DIST_ARCH**: image architecture [armel (rpi), armhf (rpi2, default)]
* **IMAGE_MB**: size of the image, 32MB is for the fat boot, which is included in this option (640 default, thus 608MB for the root partition)
* **LOCALE**: system locale (Default en_US.UTF-8) `Make sure you type this exactly like in /usr/share/i18n/SUPPORTED`
* **USER**: user account that gets created (Default pi)
* **PASS**: user account password (Default pi)
* **ROOTPASS**: root password (Default pi)

## Example: Build an RPi2 Jessie image:
Just use the make utility to build e.g. an debian-jessie-rpi2.img.  Be sure to run this with sudo, as root privileges are required to mount the image.
```
sudo make distclean && sudo make DIST=jessie DIST_ARCH=armhf IMAGE_MB=1024
```

This will install the firmware, compile the kernel, bootstrap Debian and create a 1024MB img file, which then can be transferred to a sd card (e.g. using dd):
```
sudo dd bs=1024 if=debian-jessie-rpi2.img of=/dev/YOUR_SD_CARD && sudo sync
```

## Customize your image:
It should be fairly easy to customize your image for your own needs.  You can add package names to `packages.txt`, drop scripts into the `postinst` folder and add patches to the `patches` folder, as well as add any files you want as part of the root file system into the `files` folder.  This should allow you install extra packages (e.g. using apt-get) and modify configurations to your needs.  Of course, you can do all this manually after booting the device, but the goal of this project is to be able to generate re-usable images that can be deployed on any number of RaspberryPi devices (think of it as "firmware" of a consumer device).

## Special note about config.txt
If you want to customize config.txt please just edit `files/common/etc/rpi/config.txt.template`.

## Notes
There are lots of examples, please make sure to check `files` and `postinst` and remove any options you do not want.  There are only there to show how customizable these build scripts are.
