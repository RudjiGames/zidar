--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- SVG parser, writer and helper functions
-- https://github.com/jdryg/simple-svg.git

local params		= { ... }
local SIMPSVG_ROOT	= params[1]

local SIMPSVG_INCLUDE	= {
	SIMPSVG_ROOT .. "/include",
}

local SIMPSVG_FILES		= {
	SIMPSVG_ROOT .. "/include/*.*",
	SIMPSVG_ROOT .. "/src/*.*",
}

function projectDependencies_simple_svg()
	return { "bx" }
end

function projectExtraConfig_simple_svg()
	includedirs { SIMPSVG_INCLUDE }
	defines { "BX_ALLOC=bx::alloc" }
	defines { "BX_REALLOC=bx::realloc" }
	defines { "BX_FREE=bx::free" }
	configuration { "debug or release" }
		defines { "BX_CONFIG_DEBUG=1" }
	configuration { "retail" }
		defines { "BX_CONFIG_DEBUG=0" }
	configuration {}
end

function projectAdd_simple_svg()
	addProject_3rdParty_lib("simple_svg", SIMPSVG_FILES)
end

function projectSource_simple_svg()
	return "https://github.com/jdryg/simple-svg.git"
end
