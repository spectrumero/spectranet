SUBDIRS = libspectranet socklib libhttp

.PHONY:	subdirs $(SUBDIRS)

.PHONY: clean

subdirs:	$(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

