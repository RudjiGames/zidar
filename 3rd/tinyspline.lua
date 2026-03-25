--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- ANSI C library for NURBS, B-Splines, and Bezier curves
-- https://github.com/msteinbeck/tinyspline.git

local params		= { ... }
local TSPLINE_ROOT	= params[1]

local TSPLINE_FILES = {
	TSPLINE_ROOT .. "/src/tinyspline.h",
	TSPLINE_ROOT .. "/src/tinyspline.c"
}

function projectExtraConfig_tinyspline()
	includedirs { TSPLINE_ROOT .. "/src/" }
end

function projectAdd_tinyspline()
	addProject_3rdParty_lib("tinyspline", TSPLINE_FILES)
end


function projectSource_tinyspline()
	return "https://github.com/msteinbeck/tinyspline.git"
end
