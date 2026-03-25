--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- C++ cross-platform file system watcher and notifier
-- https://github.com/SpartanJ/efsw

local params		= { ... }
local EFSW_ROOT		= params[1]

local EFSW_INCLUDE	= {
	EFSW_ROOT .. "/include",
	EFSW_ROOT .. "/src",
}

local EFSW_FILES = {
	EFSW_ROOT .. "/include/**.h",
	EFSW_ROOT .. "/src/efsw/**.h",
	EFSW_ROOT .. "/src/efsw/**.cpp"
}

function projectExtraConfig_efsw()
	includedirs { EFSW_INCLUDE }
end

function projectAdd_efsw()
	addProject_3rdParty_lib("efsw", EFSW_FILES)
end

function projectSource_efsw()
	return "https://github.com/SpartanJ/efsw"
end
