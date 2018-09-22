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
