--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Box2D is a 2D physics engine for games
-- https://github.com/erincatto/Box2D

local params		= { ... }
local BOX2D_ROOT	= params[1]

local BOX2D_INCLUDE	= {
	BOX2D_ROOT .. "/include",
	BOX2D_ROOT .. "/src",
}

local BOX2D_FILES = {
	BOX2D_ROOT .. "/include/**.h",
	BOX2D_ROOT .. "/src/**.h",
	BOX2D_ROOT .. "/src/**.cpp",
	BOX2D_ROOT .. "/src/**.h"
}

function projectExtraConfig_box2d()
	includedirs { BOX2D_INCLUDE }
end

function projectAdd_box2d()
	addProject_3rdParty_lib("box2d", BOX2D_FILES)
end

function projectSource_box2d()
	return "https://github.com/erincatto/Box2D"
end
