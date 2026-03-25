--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Nanosvg with improvements and bug fixes
-- https://github.com/RudjiGames/nanosvg2

local params		= { ... }
local NANOSVG2_ROOT	= params[1]

local NANOSVG2_INCLUDE = {
	NANOSVG2_ROOT .. "/src"
}

local NANOSVG2_FILES = {
	NANOSVG2_ROOT .. "/src/**.*"
}

function projectExtraConfig_nanosvg2()
	includedirs { NANOSVG2_ROOT .. "/src/" }
end

function projectHeaderOnlyLib_nanosvg2()
end

function projectAdd_nanosvg2()
	addProject_3rdParty_lib("nanosvg2", NANOSVG2_FILES)
end

function projectSource_nanosvg2()
	return "https://github.com/RudjiGames/nanosvg2"
end
