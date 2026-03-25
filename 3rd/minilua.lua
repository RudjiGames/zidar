--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Single-file port of Lua
-- https://github.com/edubart/minilua.git

local params		= { ... }
local MINILUA_ROOT	= params[1]

local MINILUA_INCLUDE	= {
	MINILUA_ROOT
}

local MINILUA_FILES = {
	MINILUA_ROOT .. "/src/**.h"
}

function projectExtraConfig_minilua()
	includedirs { MINILUA_INCLUDE }
end

function projectHeaderOnlyLib_minilua()
end

function projectAdd_minilua()
	addProject_3rdParty_lib("minilua", MINILUA_FILES)
end

function projectSource_minilua()
	return "https://github.com/edubart/minilua.git"
end
