--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- The Lua programming language
-- https://github.com/lua/lua

local params	= { ... }
local LUA_ROOT	= params[1]

local LUA_FILES = {
	LUA_ROOT .. "/onelua.c",
	LUA_ROOT .. "/**.h"
}

local LUA_DEFINES = {}
if getTargetOS() == "android" then
	LUA_DEFINES = { "l_getlocaledecpoint()='.'" }
end

function projectExtraConfig_lua()
	defines { LUA_DEFINES }
	includedirs { LUA_ROOT }
end

function projectAdd_lua()
	addProject_3rdParty_lib("lua", LUA_FILES)
end


function projectSource_lua()
	return "https://github.com/lua/lua"
end
