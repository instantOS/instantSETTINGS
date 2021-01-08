export PREFIX := /usr/

SUBDIRS := utils/ data/default/

.PHONY: all $(SUBDIRS)
all: install $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

.PHONY: install
install: settings.sh instantsettings.desktop instantcontrolcenter.desktop
	mkdir -p $(DESTDIR)$(PREFIX)share/instantsettings
	install -Dm 755 settings.sh $(DESTDIR)$(PREFIX)bin/instantsettings
	install -m 644 instantsettings.desktop $(DESTDIR)$(PREFIX)share/applications/
	install -m 644 instantcontrolcenter.desktop $(DESTDIR)$(PREFIX)share/applications/

.PHONY: uninstall
uninstall:
	rm -r $(DESTDIR)$(PREFIX)share/instantsettings
	rm -f $(DESTDIR)$(PREFIX)bin/instantsettings
	rm -f $(DESTDIR)$(PREFIX)share/applications/instantsettings.desktop
	rm -f $(DESTDIR)$(PREFIX)share/applications/instantcontrolcenter.desktop
