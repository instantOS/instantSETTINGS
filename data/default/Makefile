.PHONY: all
all:
	$(info Usage: make install [PREFIX=/usr/])
	true

.PHONY: install
install: appmenu browser editor filemanager lockscreen systemmonitor termeditor terminal
	mkdir -p $(DESTDIR)$(PREFIX)share/instantsettings/data/default
	for x in $^; do install -m 644 "$$x" $(DESTDIR)$(PREFIX)share/instantsettings/data/default; done

