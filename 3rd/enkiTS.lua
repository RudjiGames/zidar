--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- A permissively licensed C and C++ Task Scheduler for creating parallel programs
-- https://github.com/dougbinks/enkiTS

local params		= { ... }
local ENKITS_ROOT	= params[1]

local ENKITS_FILES = {
	ENKITS_ROOT .. "/**.h",
	ENKITS_ROOT .. "/src/**.*"
}

function projectExtraConfig_enkiTS()
 	configuration { "vs*", "windows" }
		buildoptions { "/wd4100" } -- 4100: 'pETS_': unreferenced formal parameter
	configuration { "linux-* or osx-* or *clang*" }
		buildoptions {
			"-Wno-unused-variable -Wno-unused-function -Wno-unused-parameter"
		}
	configuration {}

	includedirs { ENKITS_ROOT .. "/include/" }
end

function projectAdd_enkiTS()
	addProject_3rdParty_lib("enkiTS", ENKITS_FILES)
end

function projectSource_enkiTS()
	return "https://github.com/dougbinks/enkiTS"
end
