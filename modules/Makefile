SUBDIRS = snapman messages config basext streams

.PHONY: subdirs $(SUBDIRS)

.PHONY: clean

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

