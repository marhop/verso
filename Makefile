distfiles = verso.pl verso.conf README.md screenshot.jpg LICENSE.txt

.PHONY: dist
dist: verso.tar.gz

verso.tar.gz: $(distfiles)
	@tar -czf $@ $^

.PHONY: clean
clean:
	@rm verso.tar.gz
