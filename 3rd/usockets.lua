--
-- Copyright 2025 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--

-- https://github.com/uNetworking/uSockets.git

local params		= { ... }
local US_ROOT		= params[1]

local US_FILES = {
	US_ROOT .. "src/**.cpp",
	US_ROOT .. "src/**.h"
}

function projectDependencies_usockets()
	return { "wolfssl", "libuv", "zlib" }
end 

function projectExtraConfigExecutable_usockets()
	includedirs { US_ROOT .. "src/" }
	flags   { "Cpp20" }
end

function projectExtraConfig_usockets()
	defines {  "WITH_WOLFSSL=1", "WITH_LIBUV=1"  }
	flags   { "Cpp20" }
end
function projectAdd_usockets()
	addProject_3rdParty_lib("usockets", US_FILES)
end
