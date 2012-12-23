# Makefile for mkinitcpio

VERSION = $(shell if test -f VERSION; then cat VERSION; else git describe | sed 's/-/./g'; fi)

DIRS = \
	/usr/bin \
	/usr/share/bash-completion/completions \
	/etc/mkinitcpio.d \
	/usr/lib/initcpio/hooks \
	/usr/lib/initcpio/install \
	/usr/lib/initcpio/udev \
	/usr/share/man/man8 \
	/usr/share/man/man5 \
	/usr/share/man/man1

all: doc

MANPAGES = \
	man/mkinitcpio.8 \
	man/mkinitcpio.conf.5 \
	man/lsinitcpio.1

install: all
	mkdir -p $(DESTDIR)
	for dir in $(DIRS); do install -dm755 $(DESTDIR)/$$dir; done

	sed -e 's|^_f_config=.*|_f_config=/etc/mkinitcpio.conf|' \
	    -e 's|^_f_functions=.*|_f_functions=/usr/lib/initcpio/functions|' \
	    -e 's|^_d_hooks=.*|_d_hooks=/usr/lib/initcpio/hooks:/lib/initcpio/hooks|' \
	    -e 's|^_d_install=.*|_d_install=/usr/lib/initcpio/install:/lib/initcpio/install|' \
	    -e 's|^_d_presets=.*|_d_presets=/etc/mkinitcpio.d|' \
	    -e 's|%VERSION%|$(VERSION)|g' \
	    < mkinitcpio > $(DESTDIR)/usr/bin/mkinitcpio

	sed -e 's|\(^_f_functions\)=.*|\1=/usr/lib/initcpio/functions|' \
	    -e 's|%VERSION%|$(VERSION)|g' \
	    < lsinitcpio > $(DESTDIR)/usr/bin/lsinitcpio

	chmod 755 $(DESTDIR)/usr/bin/lsinitcpio $(DESTDIR)/usr/bin/mkinitcpio

	install -m644 mkinitcpio.conf $(DESTDIR)/etc/mkinitcpio.conf
	install -m755 init shutdown            $(DESTDIR)/usr/lib/initcpio/
	install -m644 init_functions functions $(DESTDIR)/usr/lib/initcpio/
	install -m644 01-memdisk.rules $(DESTDIR)/usr/lib/initcpio/udev/01-memdisk.rules

	cp -at $(DESTDIR)/usr/lib/initcpio hooks install
	cp -at $(DESTDIR)/etc mkinitcpio.d

	install -m644 man/mkinitcpio.8 $(DESTDIR)/usr/share/man/man8/mkinitcpio.8
	install -m644 man/mkinitcpio.conf.5 $(DESTDIR)/usr/share/man/man5/mkinitcpio.conf.5
	install -m644 man/lsinitcpio.1 $(DESTDIR)/usr/share/man/man1/lsinitcpio.1
	install -m644 bash-completion $(DESTDIR)/usr/share/bash-completion/completions/mkinitcpio
	ln -s mkinitcpio $(DESTDIR)/usr/share/bash-completion/completions/lsinitcpio

doc: $(MANPAGES)

clean:
	$(RM) mkinitcpio-${VERSION}.tar.gz $(MANPAGES)

dist: doc
	echo $(VERSION) > VERSION
	git archive --format=tar --prefix=mkinitcpio-$(VERSION)/ -o mkinitcpio-$(VERSION).tar HEAD
	bsdtar -rf mkinitcpio-$(VERSION).tar -s ,^,mkinitcpio-$(VERSION)/, $(MANPAGES) VERSION
	gzip -9 mkinitcpio-$(VERSION).tar
	$(RM) VERSION

version:
	@echo $(VERSION)

.PHONY: clean dist install tarball version
