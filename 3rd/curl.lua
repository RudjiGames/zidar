--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- A command line tool and library for transferring data with URL syntax
-- https://github.com/curl/curl.git

local params		= { ... }
local CURL_ROOT		= params[1]

local CURL_FILES = {
	CURL_ROOT .. "/lib/**.c",
	CURL_ROOT .. "/lib/**.h"
}

function projectExtraConfig_curl()
	includedirs {	CURL_ROOT .. "/include",
					CURL_ROOT .. "/lib" }

	defines { "CURL_STATICLIB", "CURL_USE_OPENSSL=1", "BUILDING_LIBCURL", "curlx_dynbuf=dynbuf" }
					   
	configuration { "vs*", "windows" }
		-- 4047 - 'const char *' differs in levels of indirection from 'int'
		-- 4024 - different types for formal and actual parameter 1
		buildoptions { "/wd4047 /wd4024"}
	configuration {}
end

function projectExtraConfigExecutable_curl()
	configuration { "linux" }
		links { "libcurl4" }
	configuration { "osx" }
		links { "libcurl4" }
	configuration { "vs*", "windows" }
		links { "Crypt32" }
	configuration {}
end

function projectAdd_curl()
	if getTargetOS() ~= "linux" and getTargetOS() ~= "osx" then
		addProject_3rdParty_lib("curl", CURL_FILES)
	end
end

function projectSource_curl()
	return "https://github.com/curl/curl.git"
end
