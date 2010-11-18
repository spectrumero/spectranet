SUBDIRS = syslib rom modules installer utils

.PHONY:	subdirs	$(SUBDIRS)

.PHONY:	clean

subdirs:	$(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

rom:	syslib

modules:	syslib

installer:	syslib rom modules utils

