--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Simple, small, efficient, C++ XML parser
-- https://github.com/leethomason/tinyxml2

local params		= { ... }
local TINYXML2_ROOT	= params[1]

local TINYXML2_FILES = {
	TINYXML2_ROOT .. "/tinyxml2.h",
	TINYXML2_ROOT .. "/tinyxml2.cpp"
}

function projectExtraConfig_tinyxml2()
	includedirs { TINYXML2_ROOT }
end

function projectAdd_tinyxml2()
	addProject_3rdParty_lib("tinyxml2", TINYXML2_FILES)
end

function projectSource_tinyxml2()
	return "https://github.com/leethomason/tinyxml2"
end
