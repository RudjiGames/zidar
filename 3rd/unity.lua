--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Simple unit testing for C
-- https://github.com/ThrowTheSwitch/Unity

local params		= { ... }
local UNITY_ROOT	= params[1]

local UNITY_FILES = {
	UNITY_ROOT .. "/src/unity.c",
	UNITY_ROOT .. "/src/unity.h"
}

local UNITY_DEFINES = {
	"UNITY_OUTPUT_COLOR",
	"UNITY_INCLUDE_EXEC_TIME",
	"UNITY_INCLUDE_EXEC_TIME",
	"UNITY_USE_COMMAND_LINE_ARGS"
}

function projectExtraConfig_unity()
	includedirs { UNITY_ROOT .. "/src" }
	defines { UNITY_DEFINES }
 	configuration { "vs*", "windows" }	
		buildoptions { "/wd4324" } -- 4324 - structure was padded due to alignment specifier
	configuration {}
end

function projectExtraConfigExecutable_unity()
	includedirs { UNITY_ROOT .. "/src" }
end

function projectAdd_unity()
	addProject_3rdParty_lib("unity", UNITY_FILES)
end

function projectSource_unity()
	return "https://github.com/ThrowTheSwitch/Unity.git"
end
