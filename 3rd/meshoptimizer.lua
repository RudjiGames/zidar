--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Mesh optimization library that makes meshes smaller and faster to render
-- https://github.com/zeux/meshoptimizer

local params		= { ... }
local MESHOPT_ROOT	= params[1]

local MESHOPT_INCLUDE	= {
	MESHOPT_ROOT .. "/src",
}

local MESHOPT_FILES = {
	MESHOPT_ROOT .. "/src/**.cpp",
	MESHOPT_ROOT .. "/src/**.h"
}

function projectExtraConfig_meshoptimizer()
	includedirs { MESHOPT_INCLUDE }
end

function projectAdd_meshoptimizer()
	addProject_3rdParty_lib("meshoptimizer", MESHOPT_FILES)
end

function projectSource_meshoptimizer()
	return "https://github.com/zeux/meshoptimizer"
end
