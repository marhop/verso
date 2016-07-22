version = 0.0.0
sdistfiles = verso.pl verso.conf verso.desktop verso.svg \
			 README.md Makefile LICENSE.txt
buildfiles = verso.1.gz verso.png verso.xpm

bin = $(DESTDIR)/usr/bin/verso
conf = $(DESTDIR)/etc/verso.conf
desktop = $(DESTDIR)/usr/share/applications/verso.desktop
man = $(DESTDIR)/usr/share/man/man1/verso.1.gz
icon_xpm = $(DESTDIR)/usr/share/pixmaps/verso.xpm
icon_png = $(DESTDIR)/usr/share/icons/hicolor/48x48/apps/verso.png
icon_svg = $(DESTDIR)/usr/share/icons/hicolor/scalable/apps/verso.svg

.PHONY: all
all: $(buildfiles)

.PHONY: dist
dist: sdist

.PHONY: sdist
sdist: dist/verso-$(version).tar.gz

dist/verso-$(version).tar.gz: $(sdistfiles)
	@mkdir -p dist/verso-$(version)/
	@cp $^ dist/verso-$(version)/
	@tar -C dist/ -czf $@ verso-$(version)/

verso.1.gz: verso.pl
	@pod2man $^ | gzip -9 > $@

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

.PHONY: install
install: verso.pl verso.conf verso.desktop verso.svg $(buildfiles)
	@install -Dm 755 verso.pl $(bin)
	@install -Dm 644 verso.conf $(conf)
	@install -Dm 644 verso.desktop $(desktop)
	@install -Dm 644 verso.1.gz $(man)
	@install -Dm 644 verso.xpm $(icon_xpm)
	@install -Dm 644 verso.png $(icon_png)
	@install -Dm 644 verso.svg $(icon_svg)

.PHONY: clean
clean:
	@rm -rf $(buildfiles) dist/

.PHONY: uninstall
uninstall:
	@rm -f $(bin) $(desktop) $(man) $(icon_xpm) $(icon_png) $(icon_svg)

.PHONY: purge
purge: uninstall
	@rm -f $(conf)

