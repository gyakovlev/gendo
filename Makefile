DOCKER ?= docker

emerge_deps = $(DOCKER) build ./ \
	--progress=plain \
	--file Dockerfile.deps \
	--build-arg atom=$(filter-out -deps,$(*)) \
	--tag gendo-builder:$(@)
	
emerge_testdeps = $(DOCKER) build ./  \
	--progress=plain \
	--file Dockerfile.testdeps \
	--build-arg atom=$(filter-out -testdeps,$(*)) \
	--tag gendo-builder:$(@)

emerge_test = $(DOCKER) build ./  \
	--progress=plain \
	--file Dockerfile.test \
	--build-arg atom=$(filter-out -test,$(*)) \
	--tag gendo-builder:$(@)

emerge_pkg = $(DOCKER) build ./  \
	--progress=plain \
	--file Dockerfile.pkg \
	--build-arg atom=$(filter-out -pkg,$(*)) \
	--tag gendo-builder:$(@)


.PHONY: usage
usage:
	@echo "Please specify a target"
	@echo Usage:
	@echo "	pull:		download gentoo stage3 for your architecture and portage tree"
	@echo "	builder:	update stage3 to latest and greatest and create builder image"
	@echo "	<pkg>:		build <pkg> and run tests, optionally with category app-cat_pkg ( / replaced with an underscore )"
	@echo "	<pkg>-deps:	install <pkg> deps (--onlydeps emerge option)"
	@echo "	<pkg>-testdeps:	install <pkg> testdeps ( --with-test-deps emerge option)"
	@echo "	<pkg>-pkg:	build a package and save to ./binpkgs-<pkg>-pkg"
	@echo "	mrproper:	purge all system images and containers (DANGEROUS!!!)"
	@echo "	clean:		purge all containers (DANGEROUS!!!)"
	@echo "Example 1:"
	@echo "	make portage-test"
	@echo "		Will build latest stable portage and run tests."
	@echo "Example 2:"
	@echo "	DOCKER_HOST="ssh://remote-machine" make bash-pkg"
	@echo "		Will build latest stable bash save package to ./binpkgs-bash-pkg"


.PHONY: Makefile

.PHONY: mrproper
mrproper:
	$(DOCKER) system prune -a --filter=label=gendo
	$(DOCKER) image ls --filter=reference='gendo-builder:*'

.PHONY: clean
clean:
	$(DOCKER) container prune -f --filter=label=gendo
	$(DOCKER) image prune -f --filter=label=gendo
	$(DOCKER) volume prune -f --filter=label=gendo
	$(DOCKER) image ls --filter=reference='gendo-builder:*'

.PHONY: pull
pull:
	$(DOCKER) pull gentoo/stage3:latest
	$(DOCKER) pull gentoo/portage:latest

.PHONY: builder
builder:
	$(DOCKER) build ./ --progress=plain --file Dockerfile --tag gendo-builder:latest


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
	$(eval CID = $(shell  $(DOCKER) create gendo-builder:$@ sh))
	$(DOCKER) cp $(CID):/var/cache/binpkgs ./binpkgs-$@
	$(DOCKER) rm $(CID)

.PHONY: %
%: %-test %-pkg
	@echo $@ done
