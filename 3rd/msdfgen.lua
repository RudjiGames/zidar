--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Multi-channel signed distance field generator
-- https://github.com/Chlumsky/msdfgen

local params		= { ... }
local MSDFGEN_ROOT	= params[1]

local MSDFGEN_FILES = {
	MSDFGEN_ROOT .. "/core/**.*",
	MSDFGEN_ROOT .. "/ext/**.*",
}

function projectExtraConfig_msdfgen()
	defines { "MSDFGEN_PUBLIC= " } -- static link
end

function projectDependencies_msdfgen()
	return { "freetype2", "tinyxml2" }
end 

function projectAdd_msdfgen()
	addProject_3rdParty_lib("msdfgen", MSDFGEN_FILES)
end


function projectSource_msdfgen()
	return "https://github.com/Chlumsky/msdfgen"
end
