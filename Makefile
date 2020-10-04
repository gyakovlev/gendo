DOCKER ?= docker

emerge_deps = $(DOCKER) build ./ \
	--progress=plain \
	--file Dockerfile.deps \
	--build-arg atom=$(filter-out -deps,$(*)) \
	--tag builder:$(@)
	
emerge_testdeps = $(DOCKER) build ./  \
	--progress=plain \
	--file Dockerfile.testdeps \
	--build-arg atom=$(filter-out -testdeps,$(*)) \
	--tag builder:$(@)

emerge_test = $(DOCKER) build ./  \
	--progress=plain \
	--file Dockerfile.test \
	--build-arg atom=$(filter-out -test,$(*)) \
	--tag builder:$(@)

emerge_pkg = $(DOCKER) build ./  \
	--progress=plain \
	--file Dockerfile.pkg \
	--build-arg atom=$(filter-out -pkg,$(*)) \
	--tag builder:$(@)


.PHONY: usage
usage:
	@echo "Please specify a target"

.PHONY: Makefile

.PHONY: mrproper
mrproper:
	$(DOCKER) system prune -a -f

.PHONY: clean
clean:
	$(DOCKER) container prune -f
	$(DOCKER) image prune -f
	$(DOCKER) volume prune -f
	$(DOCKER) image ls

.PHONY: pull
pull:
	$(DOCKER) pull gentoo/stage3:latest
	$(DOCKER) pull gentoo/portage:latest

.PHONY: builder
builder:
	$(DOCKER) build ./ --progress=plain --file Dockerfile --tag builder:latest


.PHONY: %-deps
%-deps: builder
	@$(emerge_deps)

.PHONY: %-testdeps
%-testdeps: %-deps
	@$(emerge_testdeps)

.PHONY: %-test
%-test: %-testdeps
	@$(emerge_test)

.PHONY: %-pkg
%-pkg: %-deps
	@$(emerge_pkg)
	$(eval CID = $(shell  $(DOCKER) create builder:$@ sh))
	$(DOCKER) cp $(CID):/var/cache/binpkgs ./binpkgs-$@
	$(DOCKER) rm $(CID)

.PHONY: %
%: %-test %-pkg
	@echo $@ done
