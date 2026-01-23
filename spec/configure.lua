-- spec/spec_helper.lua
local busted = require("busted")
local matcher_combinators = require("matcher_combinators")

-- This registers the "assert.combinators" matchers
require("matcher_combinators.luassert")
