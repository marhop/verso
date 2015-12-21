distfiles = verso.pl verso.conf verso.desktop README.md screenshot.jpg LICENSE.txt

.PHONY: dist
dist: verso.tar.gz

verso.tar.gz: $(distfiles)
	@tar -czf $@ $^

.PHONY: clean
clean:
	@rm verso.tar.gz

.PHONY: install
install: verso.pl verso.conf verso.desktop
	@cp verso.pl /opt/verso
	@chown root:root /opt/verso
	@chmod 755 /opt/verso
	@cp verso.conf /etc/verso.conf
	@chown root:root /etc/verso.conf
	@chmod 644 /etc/verso.conf
	@cp verso.desktop /usr/share/applications/verso.desktop
	@chown root:root /usr/share/applications/verso.desktop
	@chmod 644 /usr/share/applications/verso.desktop

.PHONY: uninstall
uninstall:
	@rm -f /opt/verso /usr/share/applications/verso.desktop

.PHONY: purge
purge: uninstall
	@rm -f /etc/verso.conf
