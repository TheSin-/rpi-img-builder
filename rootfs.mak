include common.mk

.PHONY: all
all: build

.PHONY: clean
clean: delete-rootfs
	if mountpoint -q mnt; then \
		umount mnt; \
	fi
	rm -rf $(IMAGE_FILE)*.img *.img.tmp mnt multistrap.list *.example plugins.txt multistrap.err

.PHONY: distclean
distclean: delete-rootfs
	rm -rf $(wildcard $(ROOTFS_DIR).base $(ROOTFS_DIR).base.tmp)

.PHONY: delete-rootfs
delete-rootfs:
	if mountpoint -q $(ROOTFS_DIR)/proc; then \
		umount $(ROOTFS_DIR)/proc; \
	fi
	if mountpoint -q $(ROOTFS_DIR)/sys; then \
		umount $(ROOTFS_DIR)/sys; \
	fi
	if mountpoint -q $(ROOTFS_DIR)/dev; then \
		umount $(ROOTFS_DIR)/dev; \
	fi
	rm -rf $(wildcard $(ROOTFS_DIR) uInitrd)
	
.PHONY: build
build: $(IMAGE_FILE)

$(ROOTFS_DIR).base:
	if [ "$(QEMUFULL)" = "" ]; then \
		echo "ERROR: $(QEMU) not found."; \
		exit 1; \
	fi
	rm -f plugins.txt
	for j in $(REPOS); do \
		for i in plugins/$$j/*; do \
			if [ -f $$i/baseonly -a $$j != $(REPOBASE) ]; then \
				continue; \
			fi; \
			if [ -f $$i/packages -o -f $$i/preinst -o -f $$i/postinst -o -d $$i/files -o -d $$i/patches ]; then \
				echo $$i >> plugins.txt; \
			fi; \
		done; \
	done
	for i in plugins/$(DIST)/*; do \
		if [ -f $$i/packages -o -f $$i/preinst -o -f $$i/postinst -o -d $$i/files -o -d $$i/patches ]; then \
			echo $$i >> plugins.txt; \
		fi; \
	done
	for i in plugins/*; do \
		if [ -f $$i/packages -o -f $$i/preinst -o -f $$i/postinst -o -d $$i/files -o -d $$i/patches ]; then \
			echo $$i >> plugins.txt; \
		fi; \
	done
	@echo
	@echo "Building $(IMAGE_FILE)_$(TIMESTAMP).img"
	@echo "Repositories: $(REPOS)"
	@echo "Base repositories: $(REPOBASE)"
	@echo "Distribution: $(DIST)"
	@echo "Repository architecture: $(DARCH)"
	@echo "System architecture: $(ARCH)"
	@echo "Plugins: $$(cat plugins.txt | xargs | sed -e 's;plugins/;;g' -e 's; ;, ;g')"
	@echo
	@echo -n "5..."
	@sleep 1
	@echo -n "4..."
	@sleep 1
	@echo -n "3..."
	@sleep 1
	@echo -n "2..."
	@sleep 1
	@echo -n "1..."
	@sleep 1
	@echo "OK"
	if test -d "$@.tmp"; then \
		rm -rf "$@.tmp"; \
	fi
	mkdir -p $@.tmp/etc/apt/apt.conf.d
	cp apt.conf $@.tmp/etc/apt/apt.conf.d/00multistrap
	cat $(shell echo multistrap.list.in; for i in $(REPOS); do echo repos/$$i/multistrap.list.in; done | xargs) | sed -e 's,__REPOSITORIES__,$(REPOS),g' -e 's,__SUITE__,$(DIST),g' -e 's,__FSUITE__,$(FDIST),g' -e 's,__ARCH__,$(ARCH),g' > multistrap.list
	multistrap --arch $(DARCH) --file multistrap.list --dir $@.tmp 2>multistrap.err || true
	rm -f $@.tmp/etc/apt/apt.conf.d/00multistrap
	if [ -f multistrap.err ]; then \
		if grep -q '^E' multistrap.err; then \
			echo; \
			echo; \
			echo "::: Something went wrong please review multistrap.err to figure out what."; \
			echo; \
			echo =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=; \
			cat multistrap.err; \
			echo =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=; \
			echo; \
			exit 1; \
		fi; \
	fi
	cp $(QEMUFULL) $@.tmp/usr/bin
	mkdir -p $@.tmp/usr/share/fatboothack/overlays
	if test ! -f $@.tmp/etc/resolv.conf; then \
		cp /etc/resolv.conf $@.tmp/etc/; \
	fi
	# No idea why multistrap does this
	rm -f $@.tmp/lib64
	ln -s /proc/mounts $@.tmp/etc/mtab
	mv $@.tmp $@
	touch $@

$(ROOTFS_DIR): $(ROOTFS_DIR).base
	rsync --quiet --archive --devices --specials --hard-links --acls --xattrs --sparse $(ROOTFS_DIR).base/* $@
	mkdir $@/postinst
	mkdir $@/apt-keys
	touch $@/packages.txt
	for i in $$(cat plugins.txt | xargs); do \
		echo "Processing $$i..."; \
		if [ -d $$i/files ]; then \
			echo " - found files ... adding"; \
			cd $$i/files && find . -type f ! -name '*~' -exec cp --preserve=mode,timestamps --parents \{\} $@ \;; \
			cd $(BASE_DIR); \
		fi; \
		if [ -f $$i/packages ]; then \
			echo " - found packages ... adding"; \
			echo -n "$$(cat $$i/packages | sed -e "s,__ARCH__,$(ARCH),g" | xargs) " >> $@/packages.txt; \
		fi; \
		if [ -f $$i/preinst ]; then \
			chmod +x $$i/preinst; \
			echo " - found preinst ... running"; \
			./$$i/preinst || exit 1; \
		fi; \
		if [ -f $$i/postinst ]; then \
			echo " - found postinst ... adding"; \
			cp $$i/postinst $@/postinst/$$(dirname $$i/postinst | rev | cut -d/ -f1 | rev)-$$(cat /dev/urandom | LC_CTYPE=C tr -dc "a-zA-Z0-9" | head -c 5); \
		fi; \
	done
	chmod +x $@/postinst/*
	cp postinstall $@
	mount -o bind /proc $@/proc
	mount -o bind /sys $@/sys
	mount -o bind /dev $@/dev
	chroot $@ /bin/bash -c "/postinstall $(DIST) $(ARCH) $(LOCALE) $(UNAME) $(UPASS) $(RPASS) $(INC_REC) $(UBOOT_DIR)"
	for i in $$(cat plugins.txt | xargs); do \
		if [ -d $$i/patches ]; then \
			for j in $$i/patches/*; do \
				patch -p0 -d $@ < $$j; \
			done; \
		fi; \
	done
	if ls plugins/*/files/etc/hostname 1> /dev/null 2>&1; then \
		cp plugins/*/files/etc/hostname $@/etc/hostname; \
	fi
	if ls plugins/$(DIST)/*/files/etc/hostname 1> /dev/null 2>&1; then \
		cp plugins/$(DIST)/*/files/etc/hostname $@/etc/hostname; \
	fi
	if [ -f $@/etc/hostname ]; then \
		if ! grep "^127.0.0.1\s*$$(cat $@/etc/hostname)\s*" $@/etc/hosts > /dev/null; then \
			sed -i "1i 127.0.0.1\\t$$(cat $@/etc/hostname)" $@/etc/hosts; \
		fi; \
	fi
	if [ -f $@/$(BOOT_DIR)/config.txt -a "$(DARCH)" = "arm64" ]; then \
		if ! grep "arm_64bit=1" $@/$(BOOT_DIR)/config.txt > /dev/null; then \
			echo "arm_64bit=1" >> $@/$(BOOT_DIR)/config.txt; \
		fi; \
	fi
	mkdir -p $@/lib/firmware/brcm
	cp brcmfmac43430-sdio.txt $@/lib/firmware/brcm/
	umount $@/proc
	umount $@/sys
	umount $@/dev
	rm -f $@/packages.txt
	rm -f $@/postinstall
	rm -rf $@/postinst/
	rm -rf $@/apt-keys/
	rm -f $@/usr/bin/$(QEMU)
	rm -f $@/etc/resolv.conf
	touch $@

$(IMAGE_FILE): $(ROOTFS_DIR)
	if test -f "$@.img.tmp"; then \
		rm "$@.img.tmp"; \
	fi
	./createimg $@.img.tmp $(BOOT_MB) $(ROOT_MB) $(BOOT_DIR) $(ROOTFS_DIR) "$(ROOT_DEV)"
	mv $@.img.tmp $@_$(TIMESTAMP).img
	@echo
	@echo "Built $(IMAGE_FILE)_$(TIMESTAMP).img"
	@echo "Repositories: $(REPOS)"
	@echo "Base repositories: $(REPOBASE)"
	@echo "Distribution: $(DIST)"
	@echo "Repository architecture: $(DARCH)"
	@echo "System architecture: $(ARCH)"
	@echo "Plugins: $$(cat plugins.txt | xargs | sed -e 's;plugins/;;g' -e 's; ;, ;g')"
	@echo
	touch $@_$(TIMESTAMP).img
