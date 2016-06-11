distfiles = verso.pl verso.conf verso.1.gz verso.desktop README.md \
	verso.xpm verso.png verso.svg screenshot.jpg LICENSE.txt
binfile = /usr/local/bin/verso
conffile = /etc/verso.conf
manfile = /usr/share/man/man1/verso.1.gz
desktopfile = /usr/share/applications/verso.desktop
iconfile_xpm = /usr/share/pixmaps/verso.xpm
iconfile_png = /usr/share/icons/hicolor/48x48/apps/verso.png
iconfile_svg = /usr/share/icons/hicolor/scalable/apps/verso.svg

.PHONY: dist
dist: verso.tar.gz

verso.tar.gz: $(distfiles)
	@tar -czf $@ $^

.PHONY: man
man: verso.1.gz

verso.1.gz: verso.pl
	@pod2man $^ | gzip -9 > $@

.PHONY: icons
icons: verso.png verso.xpm

verso.png: verso.svg
	@inkscape \
		--export-png=$@ \
		--export-area-page \
		--export-width=48 \
		--export-height=48 \
		$^ > /dev/null

verso.xpm: verso.svg
	@inkscape \
		--export-png=verso32x32.png \
		--export-area-page \
		--export-width=32 \
		--export-height=32 \
		$^ > /dev/null
	@convert verso32x32.png $@
	@rm verso32x32.png

.PHONY: clean
clean:
	@rm -f verso.tar.gz verso.1.gz verso.png verso.xpm

.PHONY: install
install: verso.pl verso.conf verso.1.gz verso.desktop verso.png verso.xpm
	@install -m 755 verso.pl $(binfile)
	@install -m 644 verso.conf $(conffile)
	@install -m 644 verso.1.gz $(manfile)
	@install -m 644 verso.desktop $(desktopfile)
	@install -m 644 verso.xpm $(iconfile_xpm)
	@install -m 644 verso.png $(iconfile_png)
	@install -m 644 verso.svg $(iconfile_svg)

.PHONY: uninstall
uninstall:
	@rm -f $(binfile) $(manfile) $(desktopfile) \
		$(iconfile_xpm) $(iconfile_png) $(iconfile_svg)

.PHONY: purge
purge: uninstall
	@rm -f $(conffile)

