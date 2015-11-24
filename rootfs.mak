include common.mk

UBOOT_BIN_DIR := $(UBOOT_SRC)/sd_fuse

.PHONY: all
all: build

.PHONY: clean
clean: delete-rootfs
	rm -rf $(wildcard $(IMAGE_FILE) $(IMAGE_FILE).tmp)
	rm -f multistrap.list
	rm -f cmdline.example

.PHONY: distclean
distclean: delete-rootfs
	rm -rf $(wildcard $(ROOTFS_DIR).base $(ROOTFS_DIR).base.tmp)

.PHONY: delete-rootfs
delete-rootfs:
	if mountpoint -q $(ROOTFS_DIR)/proc ; then umount $(ROOTFS_DIR)/proc ; fi
	if mountpoint -q $(ROOTFS_DIR)/sys ; then umount $(ROOTFS_DIR)/sys ; fi
	if mountpoint -q $(ROOTFS_DIR)/dev ; then umount $(ROOTFS_DIR)/dev ; fi
	rm -rf $(wildcard $(ROOTFS_DIR) uInitrd)
	
.PHONY: build
build: $(IMAGE_FILE)

$(ROOTFS_DIR).base:
	if test -d "$@.tmp"; then rm -rf "$@.tmp" ; fi
	mkdir -p $@.tmp
	perl -pe "s{__SUITE__}{$(DIST)}g" < multistrap.list.in | perl -pe "s{__ARCH__}{$(ARCH)}g" > multistrap.list
	multistrap --no-auth --arch $(DIST_ARCH) --file multistrap.list --dir $@.tmp
	cp `which qemu-arm-static` $@.tmp/usr/bin
	mkdir -p $@.tmp/usr/share/fatboothack/overlays
	if test ! -f $@.tmp/etc/resolv.conf; then cp /etc/resolv.conf $@.tmp/etc/; fi
	# No idea why multistrap does this
	rm -f $@.tmp/lib64
	ln -s /proc/mounts $@.tmp/etc/mtab
	mv $@.tmp $@
	touch $@

$(ROOTFS_DIR): $(ROOTFS_DIR).base
	rsync --quiet --archive --devices --specials --hard-links --acls --xattrs --sparse $(ROOTFS_DIR).base/* $@
	cd files/common; find . -type f ! -name '*~' -exec cp --preserve=mode,timestamps --parents \{\} ../../$@ \;
	if [ -d files/$(DIST) ]; then cd files/$(DIST); find . -type f ! -name '*~' -exec cp --preserve=mode,timestamps --parents \{\} ../../$@ \;; fi
	mount -o bind /proc $@/proc
	mount -o bind /sys $@/sys
	mount -o bind /dev $@/dev
	cp cmdline.txt.template $@/boot/cmdline.txt
	cp packages.txt $@
	cp postinstall $@
	if [ -d "postinst" ]; then cp -r postinst $@ ; fi
	chroot $@ /bin/bash -c "/postinstall $(DIST) $(DIST_URL) $(PASS) $(USER) $(ROOTPASS)"
	for i in patches/*.patch ; do patch -p0 -d $@ < $$i ; done
	if [ -d patches/$(DIST) ]; then for i in patches/$(DIST)/*.patch; do patch -p0 -d $@ < $$i ; done fi
	if [ -f files/common/etc/hostname ]; then cp files/common/etc/hostname $@/etc/hostname; fi
	if [ -f files/$(DIST)/etc/hostname ]; then cp files/$(DIST)/etc/hostname $@/etc/hostname; fi
	if [ -f $@/etc/hostname ]; then if ! grep "^127.0.0.1\s*$hostname\s*" $@/etc/hosts > /dev/null ; then sed -i "1i 127.0.0.1\\t$(cat $@/etc/hostname)" $@/etc/hosts; fi; fi
	umount $@/proc
	umount $@/sys
	umount $@/dev
	rm -f $@/packages.txt
	rm -f $@/postinstall
	rm -rf $@/postinst/
	rm -f $@/usr/bin/qemu-arm-static
	rm -f $@/etc/resolv.conf
	touch $@

$(IMAGE_FILE): $(ROOTFS_DIR)
	if test -f "$@.tmp"; then rm "$@.tmp" ; fi
	./createimg $@.tmp $(BOOT_MB) $(ROOT_MB) $(ROOTFS_DIR)/$(BOOT_DIR) $(ROOTFS_DIR) "$(ROOT_DEV)"
	mv $@.tmp $@
	touch $@

