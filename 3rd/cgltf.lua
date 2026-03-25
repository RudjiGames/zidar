--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Single-file glTF 2.0 loader and writer written in C99
-- https://github.com/jkuhlmann/cgltf.git

local params		= { ... }
local CGLTF_ROOT	= params[1]

local CGLTF_INCLUDE	= {
	CGLTF_ROOT
}

local CGLTF_FILES = {
	CGLTF_ROOT .. "/*.h"
}

function projectHeaderOnlyLib_cgltf()
end

function projectExtraConfig_cgltf()
	includedirs { CGLTF_INCLUDE }
	projectDependencyConfig_bx()
end

function projectAdd_cgltf()
	addProject_3rdParty_lib("cgltf", CGLTF_FILES)
end


function projectSource_cgltf()
	return "https://github.com/jkuhlmann/cgltf.git"
end
