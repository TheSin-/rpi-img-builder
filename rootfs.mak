include common.mk

.PHONY: all
all: build

.PHONY: clean
clean: delete-rootfs
	@umount mnt || true
	rm -rf $(wildcard $(IMAGE_FILE)) *.img.tmp mnt multistrap.list *.example plugins.txt

.PHONY: distclean
distclean: delete-rootfs
	rm -rf $(wildcard $(ROOTFS_DIR).base $(ROOTFS_DIR).base.tmp)

.PHONY: delete-rootfs
delete-rootfs:
	@if mountpoint -q $(ROOTFS_DIR)/proc ; then umount $(ROOTFS_DIR)/proc ; fi
	@if mountpoint -q $(ROOTFS_DIR)/sys ; then umount $(ROOTFS_DIR)/sys ; fi
	@if mountpoint -q $(ROOTFS_DIR)/dev ; then umount $(ROOTFS_DIR)/dev ; fi
	rm -rf $(wildcard $(ROOTFS_DIR) uInitrd)
	
.PHONY: build
build: $(IMAGE_FILE)

$(ROOTFS_DIR).base:
	@rm -f plugins.txt
	@for i in plugins/*; do if [ -f $$i/packages -o -f $$i/preinst -o -f $$i/postinst -o -d $$i/files -o -d $$i/patches ]; then echo $$i >> plugins.txt; fi; done
	@for i in plugins/$(DIST)/*; do if [ -f $$i/packages -o -f $$i/preinst -o -f $$i/postinst -o -d $$i/files -o -d $$i/patches ]; then echo $$i >> plugins.txt; fi; done
	@for j in $(REPOS); do for i in plugins/$$j/*; do if [ -f $$i/baseonly -a $$j != $(REPOBASE) ]; then continue; fi; if [ -f $$i/packages -o -f $$i/preinst -o -f $$i/postinst -o -d $$i/files -o -d $$i/patches ]; then echo $$i >> plugins.txt; fi; done; done
	@echo
	@echo "Building $(IMAGE_FILE)"
	@echo "Repositories: $(REPOS)"
	@echo "Base repositories: $(REPOBASE)"
	@echo "Distribution: $(DIST)"
	@echo "Repository architecture: $(DIST_ARCH)"
	@echo "System architecture: $(ARCH)"
	@echo "Plugins: $$(cat plugins.txt | xargs | sed -e 's;plugins/;;g' -e 's; ;, ;g')"
	@echo
	@echo -n "5... "
	@sleep 1
	@echo -n "4... "
	@sleep 1
	@echo -n "3... "
	@sleep 1
	@echo -n "2... "
	@sleep 1
	@echo -n "1... "
	@sleep 1
	@echo "OK"
	@if test -d "$@.tmp"; then rm -rf "$@.tmp" ; fi
	@mkdir -p $@.tmp
	@cat $(shell echo multistrap.list.in; for i in $(REPOS); do echo repos/$$i/multistrap.list.in; done | xargs) | sed -e 's,__REPOSITORIES__,$(REPOS),g' -e 's,__SUITE__,$(DIST),g' -e 's,__ARCH__,$(ARCH),g' > multistrap.list
	@multistrap --arch $(DIST_ARCH) --file multistrap.list --dir $@.tmp
	@cp `which qemu-arm-static` $@.tmp/usr/bin
	@mkdir -p $@.tmp/usr/share/fatboothack/overlays
	@if test ! -f $@.tmp/etc/resolv.conf; then cp /etc/resolv.conf $@.tmp/etc/; fi
	# No idea why multistrap does this
	@rm -f $@.tmp/lib64
	@ln -s /proc/mounts $@.tmp/etc/mtab
	@mv $@.tmp $@
	touch $@

$(ROOTFS_DIR): $(ROOTFS_DIR).base
	@rsync --quiet --archive --devices --specials --hard-links --acls --xattrs --sparse $(ROOTFS_DIR).base/* $@
	@mkdir $@/postinst
	@touch $@/packages.txt
	@for i in $$(cat plugins.txt | xargs); do echo "Processing $$i..."; if [ -d $$i/files ]; then echo " - found files ... adding"; cd $$i/files && find . -type f ! -name '*~' -exec cp --preserve=mode,timestamps --parents \{\} $@ \;; cd $(BASE_DIR); fi; if [ -f $$i/packages ]; then echo " - found packages ... adding"; echo -n "$$(cat $$i/packages | sed -e "s,__ARCH__,$(ARCH),g" | xargs) " >> $@/packages.txt; fi; if [ -f $$i/preinst ]; then chmod +x $$i/preinst; echo " - found preinst ... running"; ./$$i/preinst; fi; if [ -f $$i/postinst ]; then echo " - found postinst ... adding"; cp $$i/postinst $@/postinst/$$(dirname $$i/postinst | rev | cut -d/ -f1 | rev)-$$(cat /dev/urandom | LC_CTYPE=C tr -dc "a-zA-Z0-9" | head -c 5); fi; done
	@chmod +x $@/postinst/*
	@cp postinstall $@
	@mount -o bind /proc $@/proc
	@mount -o bind /sys $@/sys
	@mount -o bind /dev $@/dev
	@chroot $@ /bin/bash -c "/postinstall $(DIST) $(ARCH) $(LOCALE) $(UNAME) $(UPASS) $(RPASS) $(INC_REC)"
	@for i in $$(cat plugins.txt | xargs); do if [ -d $$i/patches ]; then for j in $$i/patches/*; do patch -p0 -d $@ < $$j; done; fi; done
	@if ls plugins/*/files/etc/hostname 1> /dev/null 2>&1; then cp plugins/*/files/etc/hostname $@/etc/hostname; fi
	@if ls plugins/$(DIST)/*/files/etc/hostname 1> /dev/null 2>&1; then cp plugins/$(DIST)/*/files/etc/hostname $@/etc/hostname; fi
	@if [ -f $@/etc/hostname ]; then if ! grep "^127.0.0.1\s*$$(cat $@/etc/hostname)\s*" $@/etc/hosts > /dev/null ; then sed -i "1i 127.0.0.1\\t$$(cat $@/etc/hostname)" $@/etc/hosts; fi; fi
	@umount $@/proc
	@umount $@/sys
	@umount $@/dev
	@rm -f $@/packages.txt
	@rm -f $@/postinstall
	@rm -rf $@/postinst/
	@rm -f $@/usr/bin/qemu-arm-static
	@rm -f $@/etc/resolv.conf
	touch $@

$(IMAGE_FILE): $(ROOTFS_DIR)
	@if test -f "$@.tmp"; then rm "$@.tmp" ; fi
	@./createimg $@.tmp $(BOOT_MB) $(ROOT_MB) $(BOOT_DIR) $(ROOTFS_DIR) "$(ROOT_DEV)"
	@mv $@.tmp $@
	@echo
	@echo "Built $(IMAGE_FILE)"
	@echo "Repositories: $(REPOS)"
	@echo "Base repositories: $(REPOBASE)"
	@echo "Distribution: $(DIST)"
	@echo "Repository architecture: $(DIST_ARCH)"
	@echo "System architecture: $(ARCH)"
	@echo "Plugins: $$(cat plugins.txt | xargs | sed -e 's;plugins/;;g' -e 's; ;, ;g')"
	@echo
	touch $@
