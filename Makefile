LUAROCKS = luarocks
LUACHECK_FLAGS = \
	--codes \
	--read-globals checkArg \
	$(NULL)

.PHONY: check
check:
	@set -eu; \
	eval `$(LUAROCKS) path --bin`; \
	luacheck $(LUACHECK_FLAGS) -- .

.PHONY: dist
dist:
	rm -rf _dist
	mkdir -p _dist/bin
	mkdir -p _dist/lib/tap/parser
	mkdir -p _dist/man
	mkdir -p _dist/test
	cp mutex/lib/mutex.lua		_dist/lib
	cp mutex/man/mutex		_dist/man
	cp mutex/test/mutex.lua		_dist/test
	cp tap/bin/prove.lua		_dist/bin
	cp tap/lib/harness.lua		_dist/lib/tap
	cp tap/lib/parser.lua		_dist/lib/tap
	cp tap/lib/parser/result.lua	_dist/lib/tap/parser
	cp tap/lib/statistics.lua	_dist/lib/tap
	cp tap/lib/test.lua		_dist/lib/tap
	tar -cvf OC-PHO-Programs.tar -C _dist .
	rm -rf _dist
