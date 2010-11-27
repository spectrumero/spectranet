SUBDIRS = syslib rom modules installer utils

.PHONY:	subdirs	$(SUBDIRS)

.PHONY:	clean

.PHONY: z88dk

subdirs:	$(SUBDIRS)

z88dk:
	$(MAKE) -C z88dk

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

rom:	syslib

modules:	syslib

installer:	syslib rom modules utils

