--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- C++ associative containers
-- https://github.com/sparsehash/sparsehash.git

local params		= { ... }
local SPARSEH_ROOT	= params[1]

local SPARSEH_FILES = {
	SPARSEH_ROOT .. "/src/sparsehash/*.*"
}

function projectExtraConfig_sparsehash()
	includedirs { SPARSEH_ROOT .. "/src" }
	if getTargetOS() == "windows" then
		includedirs { SPARSEH_ROOT .. "/src/windows" }	
	end
end

function projectExtraConfigExecutable_sparsehash()
	projectExtraConfig_sparsehash()
end

function projectHeaderOnlyLib_sparsehash()
end

function projectAdd_sparsehash()
	if getTargetOS() ~= "windows" then
		os.execute(SPARSEH_ROOT .. "/configure")
		os.execute("cp " .. SPARSEH_ROOT .. "/src/config.h " .. SPARSEH_ROOT .. "/src/sparsehash/internal/sparseconfig.h")
	end

	addProject_3rdParty_lib("sparsehash", SPARSEH_FILES)
end

function projectSource_sparsehash()
	return "https://github.com/sparsehash/sparsehash.git"
end
