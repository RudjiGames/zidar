--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Miniscule cross-platform eventing, networking and crypto for async applications
-- https://github.com/uNetworking/uSockets.git

local params		= { ... }
local US_ROOT		= params[1]

local US_FILES = {
	US_ROOT .. "/src/**.cpp",
	US_ROOT .. "/src/**.h"
}

function projectDependencies_usockets()
	return { "wolfssl", "libuv", "zlib" }
end 

function projectExtraConfigExecutable_usockets()
	includedirs { US_ROOT .. "/src/" }
	flags   { "Cpp20" }
end

function projectExtraConfig_usockets()
	defines {  "WITH_WOLFSSL=1", "WITH_LIBUV=1"  }
	flags   { "Cpp20" }
end
function projectAdd_usockets()
	addProject_3rdParty_lib("usockets", US_FILES)
end

function projectSource_usockets()
	return "https://github.com/uNetworking/uSockets.git"
end
