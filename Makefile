distfiles = verso.pl verso.conf verso.1.gz verso.desktop README.md \
	screenshot.jpg LICENSE.txt
binfile = /usr/local/bin/verso
conffile = /etc/verso.conf
manfile = /usr/share/man/man1/verso.1.gz
desktopfile = /usr/share/applications/verso.desktop

.PHONY: dist
dist: verso.tar.gz

verso.tar.gz: $(distfiles)
	@tar -czf $@ $^

.PHONY: man
man: verso.1.gz

verso.1.gz: manpage.md
	@pandoc -f markdown -t man -s $^ | gzip -9 > $@

.PHONY: clean
clean:
	@rm -f verso.tar.gz verso.1.gz

.PHONY: install
install: verso.pl verso.conf verso.1.gz verso.desktop
	@install -m 755 verso.pl $(binfile)
	@install -m 644 verso.conf $(conffile)
	@install -m 644 verso.1.gz $(manfile)
	@install -m 644 verso.desktop $(desktopfile)

.PHONY: uninstall
uninstall:
	@rm -f $(binfile) $(manfile) $(desktopfile)

.PHONY: purge
purge: uninstall
	@rm -f $(conffile)

