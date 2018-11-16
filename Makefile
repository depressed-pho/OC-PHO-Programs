LUAROCKS = luarocks
LUACHECK_FLAGS = \
	--codes \
	--read-globals checkArg \
	$(NULL)

PAGER ?= more

.PHONY: check
check:
	@set -eu; \
	eval `$(LUAROCKS) path --bin`; \
	luacheck $(LUACHECK_FLAGS) -- .


.PHONY: fixme
fixme:
	@git ls-files | \
	grep -v Makefile | \
	(xargs grep -n -E '(FIXME|THINKME|TODO)' --color=always || \
		echo 'No FIXME, THINKME, nor TODO were found.') | \
	$(PAGER)

.PHONY: dist
dist:
	rm -rf _dist
	mkdir -p _dist/bin
	mkdir -p _dist/lib/ansi-terminal
	mkdir -p _dist/lib/containers
	mkdir -p _dist/lib/tap/parser
	mkdir -p _dist/lib/program-options
	mkdir -p _dist/lib/wl-pprint
	mkdir -p _dist/man/containers
	mkdir -p _dist/test/containers
	mkdir -p _dist/test/program-options
	cp algebraic-data-types/lib/*.lua	_dist/lib
	cp algebraic-data-types/man/*		_dist/man
	cp algebraic-data-types/test/*.lua	_dist/test
	cp ansi-terminal/lib/ansi-terminal.lua	_dist/lib
	cp ansi-terminal/lib/*.lua		_dist/lib/ansi-terminal
	cp ansi-terminal/man/*			_dist/man
	cp ansi-terminal/test/*.lua		_dist/test
	cp containers/lib/*.lua		_dist/lib/containers
	cp containers/man/*		_dist/man/containers
	cp containers/test/*.lua	_dist/test/containers
	cp lazy/lib/*.lua		_dist/lib
	cp lazy/man/*			_dist/man
	cp lazy/test/*.lua		_dist/test
	cp mutex/lib/*.lua		_dist/lib
	cp mutex/man/*			_dist/man
	cp mutex/test/*.lua		_dist/test
	cp tap/bin/*.lua		_dist/bin
	cp tap/lib/parser/*.lua		_dist/lib/tap/parser
	cp program-options/lib/program-options.lua	_dist/lib
	cp program-options/lib/*.lua	_dist/lib/program-options
	cp program-options/man/program-options	_dist/man
	cp program-options/test/*.lua	_dist/test
	cp wl-pprint/lib/wl-pprint.lua	_dist/lib
	cp wl-pprint/lib/*.lua		_dist/lib/wl-pprint
	cp wl-pprint/man/*		_dist/man
	cp wl-pprint/test/*.lua		_dist/test
	tar -cvf OC-PHO-Programs.tar -C _dist .
	rm -rf _dist
