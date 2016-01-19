distfiles = verso.pl verso.conf verso.desktop README.md screenshot.jpg LICENSE.txt
binfile = /usr/local/bin/verso
conffile = /etc/verso.conf
desktopfile = /usr/share/applications/verso.desktop

.PHONY: dist
dist: verso.tar.gz

verso.tar.gz: $(distfiles)
	@tar -czf $@ $^

.PHONY: clean
clean:
	@rm verso.tar.gz

.PHONY: install
install: verso.pl verso.conf verso.desktop
	@install -m 755 verso.pl $(binfile)
	@install -m 644 verso.conf $(conffile)
	@install -m 644 verso.desktop $(desktopfile)

.PHONY: uninstall
uninstall:
	@rm -f $(binfile) $(desktopfile)

.PHONY: purge
purge: uninstall
	@rm -f $(conffile)

