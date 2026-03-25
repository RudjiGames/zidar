--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Header-only TOML config file parser and serializer for C++17
-- https://github.com/edubart/tomlplusplus.git

local params		= { ... }
local TOMLPP_ROOT	= params[1]

local TOMLPP_INCLUDE	= {
	TOMLPP_ROOT .. "/include"
}

local TOMLPP_FILES = {
	TOMLPP_ROOT .. "/include/**.h",
	TOMLPP_ROOT .. "/src/**.cpp"
}

function projectExtraConfig_tomlplusplus()
	includedirs { TOMLPP_INCLUDE }
end

function projectAdd_tomlplusplus()
	addProject_3rdParty_lib("tomlplusplus", TOMLPP_FILES)
end

function projectSource_tomlplusplus()
	return "https://github.com/edubart/tomlplusplus.git"
end
