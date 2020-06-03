all: dist

# dist builds binaries for all platforms and packages them for distribution
dist:
	sh -c "'$(CURDIR)/scripts/dist.sh'"