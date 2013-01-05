# Makefile for mkinitcpio

VERSION = $(shell if test -f VERSION; then cat VERSION; else git describe | sed 's/-/./g'; fi)

DIRS = \
	/bin \
	/usr/share/bash-completion/completions \
	/etc/mkinitcpio.d \
	/lib/initcpio/hooks \
	/lib/initcpio/install \
	/lib/initcpio/udev \
	/doc/man/man8 \
	/doc/man/man5 \
	/doc/man/man1

all: doc

MANPAGES = \
	man/mkinitcpio.8 \
	man/mkinitcpio.conf.5 \
	man/lsinitcpio.1

install: all
	mkdir -p $(DESTDIR)
	for dir in $(DIRS); do install -dm755 $(DESTDIR)/$$dir; done

	sed -e 's|^_f_config=.*|_f_config=/etc/mkinitcpio.conf|' \
	    -e 's|^_f_functions=.*|_f_functions=/lib/initcpio/functions|' \
	    -e 's|^_d_hooks=.*|_d_hooks=/lib/initcpio/hooks|' \
	    -e 's|^_d_install=.*|_d_install=/lib/initcpio/install|' \
	    -e 's|^_d_presets=.*|_d_presets=/etc/mkinitcpio.d|' \
	    -e 's|%VERSION%|$(VERSION)|g' \
	    < mkinitcpio > $(DESTDIR)/bin/mkinitcpio

	sed -e 's|\(^_f_functions\)=.*|\1=/lib/initcpio/functions|' \
	    -e 's|%VERSION%|$(VERSION)|g' \
	    < lsinitcpio > $(DESTDIR)/bin/lsinitcpio

	chmod 755 $(DESTDIR)/bin/lsinitcpio $(DESTDIR)/bin/mkinitcpio

	install -m644 mkinitcpio.conf $(DESTDIR)/etc/mkinitcpio.conf
	install -m755 init shutdown            $(DESTDIR)/lib/initcpio/
	install -m644 init_functions functions $(DESTDIR)/lib/initcpio/
	install -m644 01-memdisk.rules $(DESTDIR)/lib/initcpio/udev/01-memdisk.rules

	cp -r hooks install $(DESTDIR)/lib/initcpio
	cp -r mkinitcpio.d $(DESTDIR)/etc

	install -m644 man/mkinitcpio.8 $(DESTDIR)/doc/man/man8/mkinitcpio.8
	install -m644 man/mkinitcpio.conf.5 $(DESTDIR)/doc/man/man5/mkinitcpio.conf.5
	install -m644 man/lsinitcpio.1 $(DESTDIR)/doc/man/man1/lsinitcpio.1
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
