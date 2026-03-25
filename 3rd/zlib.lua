--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- A massively spiffy yet delicately unobtrusive compression library
-- https://github.com/madler/zlib

local params		= { ... }
local ZLIB_ROOT		= params[1]

local ZLIB_FILES = {
	ZLIB_ROOT .. "/*.c",
	ZLIB_ROOT .. "/*.h"
}

local ZLIB_DEFINES = {}
if getTargetOS() == "android" then
	ZLIB_DEFINES = {
		"fopen64=fopen",
		"ftello64=ftell",
		"fseeko64=fseek",
	}
end

function projectExtraConfig_zlib()
	includedirs { ZLIB_ROOT }
	defines { ZLIB_DEFINES }

	configuration { "linux" }
		forcedincludes { "unistd.h" }
	configuration { "osx" }
		forcedincludes { "unistd.h" }
	configuration {}
end

function projectExtraConfigExecutable_zlib()
	includedirs { ZLIB_ROOT }
end

function projectAdd_zlib()
	addProject_3rdParty_lib("zlib", ZLIB_FILES)
end


function projectSource_zlib()
	return "https://github.com/madler/zlib"
end
