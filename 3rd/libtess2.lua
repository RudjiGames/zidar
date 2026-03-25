--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Game and tools oriented refactored version of GLU tesselator
-- https://github.com/memononen/libtess2.git

local params		= { ... }
local LIBTESS2_ROOT	= params[1]

local LIBTESS2_FILES = {
	LIBTESS2_ROOT .. "/Source/*.c",
	LIBTESS2_ROOT .. "/Source/*.h",
}

function projectExtraConfig_libtess2()
	includedirs { LIBTESS2_ROOT .. "/Include" }
end

function projectAdd_libtess2()
	addProject_3rdParty_lib("libtess2", LIBTESS2_FILES)
end

function projectSource_libtess2()
	return "https://github.com/memononen/libtess2.git"
end
