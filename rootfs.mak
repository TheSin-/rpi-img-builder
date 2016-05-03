include common.mk

.PHONY: all
all: build

.PHONY: clean
clean: delete-rootfs
	rm -rf $(wildcard $(IMAGE_FILE))
	rm -rf *.img.tmp
	rm -rf mnt
	rm -f multistrap.list
	rm -f *.example

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
	cat $(shell echo multistrap.list.in; for i in $(REPOS); do echo repos/$$i/multistrap.list.in; done | xargs) | perl -pe "s{__REPOSITORIES__}{$(REPOS)}g" | perl -pe "s{__SUITE__}{$(DIST)}g" | perl -pe "s{__ARCH__}{$(ARCH)}g" > multistrap.list
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
	cd plugins; for i in */files; do if [ -d $$i ]; then cd $$i && find . -type f ! -name '*~' -exec cp --preserve=mode,timestamps --parents \{\} ../../../$@ \;; cd ../..; fi; done
	if [ -d plugins/$(DIST) ]; then cd plugins/$(DIST); for i in */files; do if [ -d $$i ]; then cd $$i; find . -type f ! -name '*~' -exec cp --preserve=mode,timestamps --parents \{\} ../../../../$@ \;; cd ../../..; fi; done; fi
	if [ -d plugins/$(REPOBASE) ]; then cd plugins/$(REPOBASE); for i in */files; do if [ -d $$i ]; then cd $$i; find . -type f ! -name '*~' -exec cp --preserve=mode,timestamps --parents \{\} ../../../../$@ \;; cd ../../..; fi; done; fi
	cat plugins/*/packages plugins/$(DIST)/*/packages plugins/$(REPOBASE)/*/packages 2>/dev/null | sed -e "s,__ARCH__,$(ARCH),g" | xargs > $@/packages.txt
	if ls plugins/*/preinst 1> /dev/null 2>&1; then for i in plugins/*/preinst; do chmod +x $$i; echo Running ./$$i; ./$$i; done; fi
	if ls plugins/$(DIST)/*/preinst 1> /dev/null 2>&1; then for i in plugins/$(DIST)/*/preinst; do chmod +x $$i; echo Running ./$$i; ./$$i; done; fi
	if ls plugins/$(REPOBASE)/*/preinst 1> /dev/null 2>&1; then for i in plugins/$(REPOBASE)/*/preinst; do chmod +x $$i; echo Running ./$$i; ./$$i; done; fi
	mkdir $@/postinst
	if ls plugins/*/postinst 1> /dev/null 2>&1; then for i in plugins/*/postinst; do cp $$i $@/postinst/$$(dirname $$i | cut -d/ -f2)-$$(cat /dev/urandom | LC_CTYPE=C tr -dc "a-zA-Z0-9" | head -c 5); done; fi
	if ls plugins/$(DIST)/*/postinst 1> /dev/null 2>&1; then for i in plugins/$(DIST)/*/postinst; do cp $$i $@/postinst/$(DIST)-$$(dirname $$i | cut -d/ -f3)-$$(cat /dev/urandom | LC_CTYPE=C tr -dc "a-zA-Z0-9" | head -c 5); done; fi
	if plugins/$(REPOBASE)/*/postinst 1> /dev/null 2>&1; then for i in plugins/$(REPOBASE)/*/postinst; do cp $$i $@/postinst/$(REPOBASE)-$$(dirname $$i | cut -d/ -f3)-$$(cat /dev/urandom | LC_CTYPE=C tr -dc "a-zA-Z0-9" | head -c 5); done; fi
	chmod +x $@/postinst/*
	cp postinstall $@
	mount -o bind /proc $@/proc
	mount -o bind /sys $@/sys
	mount -o bind /dev $@/dev
	chroot $@ /bin/bash -c "/postinstall $(DIST) $(ARCH) $(LOCALE) $(UNAME) $(UPASS) $(RPASS)"
	for i in plugins/*/patches/*.patch; do if [ -f $$i ]; then patch -p0 -d $@ < $$i; fi; done
	if ls plugins/$(DIST)/*/patches/* 1> /dev/null 2>&1; then for i in plugins/$(DIST)/*/patches/*.patch; do if [ -f $$i ]; then patch -p0 -d $@ < $$i; fi; done; fi
	if ls plugins/*/files/etc/hostname 1> /dev/null 2>&1; then cp plugins/*/files/etc/hostname $@/etc/hostname; fi
	if ls plugins/$(DIST)/*/files/etc/hostname 1> /dev/null 2>&1; then cp plugins/$(DIST)/*/files/etc/hostname $@/etc/hostname; fi
	if [ -f $@/etc/hostname ]; then if ! grep "^127.0.0.1\s*$$(cat $@/etc/hostname)\s*" $@/etc/hosts > /dev/null ; then sed -i "1i 127.0.0.1\\t$$(cat $@/etc/hostname)" $@/etc/hosts; fi; fi
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
