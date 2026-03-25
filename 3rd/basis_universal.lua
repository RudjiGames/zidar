--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Basis Universal GPU Texture Codec
-- https://github.com/BinomialLLC/basis_universal

local params	    	= { ... }
local BASIS_ROOT    	= params[1]

local BASIS_INCLUDE	= {
	BASIS_ROOT .. "/encoder",
	BASIS_ROOT .. "/transcoder",
}

local BASIS_FILES = {
	BASIS_ROOT .. "/encoder/**.h",
	BASIS_ROOT .. "/encoder/**.cpp",
	BASIS_ROOT .. "/transcoder/**.h",
    BASIS_ROOT .. "/transcoder/**.cpp",
    BASIS_ROOT .. "/transcoder/**.inc"
} 

function projectDependencies_basis_universal()
	return {}
end 

function projectExtraConfig_basis_universal()
	includedirs { BASIS_INCLUDE }
end

function projectAdd_basis_universal()
	addProject_3rdParty_lib("basis_universal", BASIS_FILES)
end

function projectSource_basis_universal()
	return "https://github.com/BinomialLLC/basis_universal"
end
