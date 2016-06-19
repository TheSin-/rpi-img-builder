rpi-img-builder
===============

Script to build custom sd card image for Raspberry Pi.

## Features:
* Debian repository (Tested with Jessie so far)
* Raspbian repository ([jessie/wheezy]/armhf ONLY)
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
* Many more added all the time, check the plugins directory for more

## Make Options
The build process has a few options you can set.
* **DIST**: debian distribution [default jessie]
* **DIST_ARCH**: image architecture [armel, armhf (default), arm64]
* **REPOSITORIES**: upstream repositories based on repos dir [Bluefalls, Debian, Rasbian, "Debian Bluefalls" (default)]
* **ARCH**: used to determin the kernel name [[Bluefalls - rpi, rpi2 (default), rpi3], [Debian - armmp (default), armmp-lpae], [Raspbian - no option]]
* **IMAGE_MB**: size of the image, 32MB is for the fat boot, which is included in this option [-1 = auto (default), n = size in MB]
* **LOCALE**: system locale (en_US.UTF-8 default, Make sure you type this exactly like in /usr/share/i18n/SUPPORTED)
* **UNAME**: user account that gets created (pi default)
* **UPASS**: user account password (pi default)
* **RPASS**: root password (pi default)
* **INC_REC**: include recommends for apt-get install [1 = Yes, 0 = No (default)]

## Prerequisites:
On a x86 based Debian system, make sure the following packages are installed:
```
sudo apt-get install build-essential wget git lzop u-boot-tools binfmt-support \
                     qemu qemu-user-static multistrap parted dosfstools
```

## Example: Build an RPi2 Jessie image with a forced size of 1G:
Just use the make utility to build e.g. an Bluefalls-jessie-rpi2.img.  Be sure to run this with sudo, as root privileges are required to mount the image.
```
sudo make distclean && sudo make DIST=jessie DIST_ARCH=armhf IMAGE_MB=1024
```

This will install the firmware, compile the kernel, bootstrap Debian and create a 1024MB img file, which then can be transferred to a sd card (e.g. using dd):
```
sudo dd bs=1M if=Bluefalls-jessie-rpi2.img of=/dev/YOUR_SD_CARD && sudo sync
```

## Example: Build a Debian U-Boot Testing image based on armmp:
Just use the make utility to build e.g. an Debian-testing-armmp.img.  Be sure to run this with sudo, as root privileges are required to mount the image.
*NOTE:* usbmount isn't in testing, and sounds drivers aren't avail in debian kernel, so move both out of the way.
```
mv plugins/usbmount plugins/disabled/
mv plugins/alsa plugins/disabled/
sudo make distclean && sudo make ARCH=armmp DIST=testing REPOSITORIES=Debian
```

## Customize your image:
## Example: Build a Raspbian Jessie image:
Just use the make utility to build e.g. an Rasbian-jessie-rpix.img.  Be sure to run this with sudo, as root privileges are required to mount the image.
```
sudo make distclean && sudo make REPOSITORIES=Raspbian
```

## Customize your image:
It should be fairly easy to customize your image for your own needs.  Bulding and adding plugins is easy.  Each plugin can contain:
* **packages**: file with one line containing debian packages to install
* **preinst**: script to run pre chroot
* **postinst**: script to run in chroot of the rootfs
* **files**: dir which conatins files to be copied into the rootfs, perms and atts included
* **patches**: dir which contains patch files to apply to the rootfs

Order is files -> preinst -> packages -> postinst -> patches

This should allow you install extra packages (e.g. using apt-get) and modify configurations to your needs.  Of course, you can do all this manually after booting the device, but the goal of this project is to be able to generate re-usable images that can be deployed on any number of RaspberryPi devices (think of it as "firmware" of a consumer device).  The `extrapackages` plugin is an example of a plugin to just add new packages, you can modify it or create a new plugin of your own.

## Plugin directory structure
All plugins in the base of the plugins dir will be included, if you do not want a plugin included move it to the disabled directory within the plugins directory.  There are a few special cases, and subdirectory in the plugins directory that match an enable Reporitory (via REPOSITORIES option or the defaults) or Distribution (vis DIST option or the default) could have a sub set of plugins without a directory that is named like it.

For example, if you set DIST to stretch and REPSOTORIES to Raspbian, then all plugins in the base of the plugins dir will be include as well as the plugins in the stretch and Raspbian directories.  Also since Raspbian will auto add the Foundation repo, any plugins in the Foundation directory if it exists will be included as well.

## Repositories
So repositories require others, for example Raspbian will auto add Foundation, and Bluefalls with auto add Debian.

You can easily add a custom repo by making a directory in the repos dir with teh repo name and making a multistrap.list.in file (see the others in that directory for examples on the files contents) and then listing it in the REPOSITORIES options.  ie: make an ubuntu repo, I could then use REPOSITORIES="Raspbian ubuntu", this is just an example I'm not sure why you would do this, but as an example.

## Notes
There are lots of plugin examples included, you can add and remove to your needs.  There are only there to show how customizable these build scripts are.

## Credits
Some tweaks and info for this project was taken in whole or part from:
* https://github.com/RPi-Distro/pi-gen
* https://github.com/ShorTie8/my_pi_os
