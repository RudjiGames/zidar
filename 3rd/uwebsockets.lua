--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Simple, secure and standards compliant web server
-- https://github.com/uNetworking/uWebSockets

local params		= { ... }
local UWS_ROOT		= params[1]

local UWS_FILES = {
	UWS_ROOT .. "/src/**.cpp",
	UWS_ROOT .. "/src/**.h"
}

function projectDependencies_uwebsockets()
	return { "usockets", "wolfssl", "libuv", "zlib" }
end 

function projectExtraConfigExecutable_uwebsockets()
	includedirs { UWS_ROOT .. "/src/" }
	flags   { "Cpp20" }
end

function projectHeaderOnlyLib_uwebsockets()
end

function projectExtraConfig_uwebsockets()
	defines {  "WITH_WOLFSSL=1", "WITH_LIBUV=1"  }
	flags   { "Cpp20" }
end
function projectAdd_uwebsockets()
	addProject_3rdParty_lib("uwebsockets", UWS_FILES)
end

function projectSource_uwebsockets()
	return "https://github.com/uNetworking/uWebSockets"
end
