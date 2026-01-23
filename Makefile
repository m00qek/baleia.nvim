.PHONY: test watch deps

# Force LuaRocks to always use Lua 5.1
LUAROCKS := luarocks --local --lua-version=5.1

# 1. Define the "Magic Prefix"
# This command asks luarocks for the correct paths (PATH, LUA_PATH, LUA_CPATH)
# and 'evals' them into the current shell session before running the command.
# We use '$$' to escape the '$' so Make passes it to the shell.
SETUP_ENV := eval $$($(LUAROCKS) path --bin)

# Default to running all specs, can be overridden with SPEC=...
SPEC ?= spec

test:
	@# Run setup, THEN run vusted
	$(SETUP_ENV) && vusted $(SPEC)

watch:
	$(SETUP_ENV) && find lua spec -name "*.lua" | entr -c sh -c "vusted $(SPEC) || true"

deps:
	$(LUAROCKS) install vusted 
	$(LUAROCKS) install matcher_combinators
	$(LUAROCKS) install luacheck
	cargo install stylua

lint:
	$(SETUP_ENV) && luacheck .
	$(SETUP_ENV) && stylua --check .
