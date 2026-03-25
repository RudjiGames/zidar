--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- SVG Tiny 1.2 compliant library
-- https://github.com/dunkelstern/libsvgtiny.git

local params			= { ... }
local LIBSVGTINY_ROOT	= params[1]

local LIBSVGTINY_FILES = {
	LIBSVGTINY_ROOT .. "/src/*.c",
	LIBSVGTINY_ROOT .. "/src/*.h",
	LIBSVGTINY_ROOT .. "/include/*.h"
}

function projectDependencies_libsvgtiny()
	return { "libxml2", "libdom" }
end 

function projectExtraConfig_libsvgtiny()
	includedirs { LIBSVGTINY_ROOT .. "/include" }
end

function projectAdd_libsvgtiny()
	addProject_3rdParty_lib("libsvgtiny", LIBSVGTINY_FILES)
end

function projectSource_libsvgtiny()
	return "https://github.com/dunkelstern/libsvgtiny.git"
end
