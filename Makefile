all: dist
.PHONY: all

# dist builds binaries for all platforms and packages them for distribution
dist:
	sh -c "'$(CURDIR)/scripts/dist.sh'"
.PHONY: dist

install_local:
	sh -c "'$(CURDIR)/scripts/install_local.sh'"
.PHONY: install_local