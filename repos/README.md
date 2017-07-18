repos
===============

This directory contains descriptions of what repositories you can use to build the root filesystem.


## Example: how to use local apt mirror

If you want to be able to reconstruct the same image in the future (for example for an enterprise firmware), it's a good idea to mirror the public repositories.

In this case, once you have local mirrors working, you only need to edit the corresponding repos/\<repo\>/multistrap.list.in

change the line:
```
source=http://http.debian.net/debian
```
to
```
source=http://<your_mirror_ip>/archive.raspberrypi.org/debian
```


Note that you should avoid:
```
source=file:///<your_local_path>
```
because it will create errors with multistrap
and
```
source=copy:///<your_local_path>
```
which is recommanded by multistrap doc, but will create issues with the generated /etc/apt/sources.list.d/\* in your generated rootfs (apt will complain about a malformed line).


## Note: how to create local apt mirrors

In my case, I wanted to mirror everything needed to construct my image for the raspberry compute module 3, so
my /etc/apt/mirror.list is:
```
set base_path   /mnt/bigdrive/raspbian_mirror
set nthreads     4
set _tilde 0
set limit_rate 100k
deb-armhf http://archive.raspbian.org/raspbian          jessie main contrib non-free
deb-armhf http://archive.raspbian.org/raspbian          jessie main firmware rpi
deb-armhf http://archive.raspberrypi.org/debian         jessie main ui
```
( which by the way as of april 2017 takes ~64Go on my hard drive ).

I then installed proftpd, activated anonymous read acces and created a mount bind:
```
sudo mount --bind /mnt/bigdrive/raspbian_apt_mirror/mirror/ /srv/ftp/
```

The two sources lines are then:

repos/Foundation/multistrap.list.in:
```
source=ftp://<your_mirror_ip>/archive.raspberrypi.org/debian
```
repos/Raspbian/multistrap.list.in:
```
source=ftp://<your_mirror_ip>/archive.raspbian.org/raspbian
```

Now I'm sure that I will always be able to reconstruct the same image, and that any packages added dynamically from apt on the running pi will be the exact same version if I add it at build time.

As a bonus, I've local network speed. :)


## Links
* https://wiki.debian.org/Multistrap/PartialMirrors
* https://www.howtoforge.com/local_debian_ubuntu_mirror

