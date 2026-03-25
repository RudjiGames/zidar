--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Antialiased 2D vector drawing library on top of OpenGL for UI and visualizations
-- https://github.com/memononen/nanovg

local params		= { ... }
local NANOVG_ROOT	= params[1]

local NANOVG_INCLUDE = {
	NANOVG_ROOT .. "/src"
}

local NANOVG_FILES = {
	NANOVG_ROOT .. "/src/**.*"
}

function projectExtraConfig_nanovg()
	includedirs { NANOVG_ROOT .. "/src/" }

 	configuration { "vs*", "windows" }	
		buildoptions { "/wd4244" } -- 4324 - '=': conversion from 'int' to 'stbi_uc', possible loss of data
 	configuration {}	
end

function projectAdd_nanovg()
	addProject_3rdParty_lib("nanovg", NANOVG_FILES)
end

function projectSource_nanovg()
	return "https://github.com/memononen/nanovg"
end
