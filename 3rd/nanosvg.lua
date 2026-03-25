--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Simple stupid SVG parser
-- https://github.com/memononen/nanosvg

local params		= { ... }
local NANOSVG_ROOT	= params[1]

local NANOSVG_INCLUDE = {
	NANOSVG_ROOT .. "/src"
}

local NANOSVG_FILES = {
	NANOSVG_ROOT .. "/src/**.*"
}

function projectExtraConfig_nanosvg()
	includedirs { NANOSVG_ROOT .. "/src/" }
end

function projectHeaderOnlyLib_nanosvg()
end

function projectAdd_nanosvg()
	addProject_3rdParty_lib("nanosvg", NANOSVG_FILES)
end

function projectSource_nanosvg()
	return "https://github.com/memononen/nanosvg"
end
