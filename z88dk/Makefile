SUBDIRS = libspectranet socklib libhttp libspdos
INSTALLDIRS = $(SUBDIRS:%=install-%)

.PHONY:	subdirs $(SUBDIRS)

.PHONY:	subdirs $(INSTALLDIRS)
.PHONY:	install

.PHONY: clean

subdirs:	$(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@
	
install:	$(INSTALLDIRS)
$(INSTALLDIRS): 
	$(MAKE) -C $(@:install-%=%) install

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

