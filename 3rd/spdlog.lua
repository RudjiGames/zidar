--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Fast C++ logging library
-- https://github.com/gabime/spdlog

local params		= { ... }
local SPDLOG_ROOT	= params[1]

local SPDLOG_INCLUDE	= {
	SPDLOG_ROOT .. "/include",
}

local SPDLOG_FILES		= {
	SPDLOG_ROOT .. "/include/*.*",
	SPDLOG_ROOT .. "/src/*.*",
}

function projectExtraConfig_spdlog()
	includedirs { SPDLOG_INCLUDE }
	defines { "SPDLOG_COMPILED_LIB" }
	configuration "vs*"
		buildoptions { "/wd 4530" }
end

function projectAdd_spdlog()
	addProject_3rdParty_lib("spdlog", SPDLOG_FILES)
end

function projectSource_spdlog()
	return "https://github.com/gabime/spdlog"
end
