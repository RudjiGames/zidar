--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Header only C++11 tiny glTF 2.0 library
-- https://github.com/syoyo/tinygltf.git

local params		= { ... }
local TINYGLTF_ROOT	= params[1]

local TINYGLTF_INCLUDE = {
	TINYGLTF_ROOT
}

local TINYGLTF_FILES = {
	TINYGLTF_ROOT .. "/tiny_gltf.h",
	TINYGLTF_ROOT .. "/tiny_gltf.cc"
}

function projectExtraConfig_tinygltf()
	includedirs { TINYGLTF_ROOT .. "/src/" }
	defines { "TINYGLTF_ALL_COLOR_KEYWORDS" }
end

function projectHeaderOnlyLib_tinygltf()
end

function projectAdd_tinygltf()
	addProject_3rdParty_lib("tinygltf", TINYGLTF_FILES)
end

function projectSource_tinygltf()
	return "https://github.com/syoyo/tinygltf.git"
end
