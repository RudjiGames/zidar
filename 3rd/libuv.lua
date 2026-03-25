--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Cross-platform asynchronous I/O
-- https://github.com/libuv/libuv.git

local params		= { ... }
local LIBUV_ROOT	= params[1]

local LIBUV_FILES = {
	LIBUV_ROOT .. "/src/*.c",
	LIBUV_ROOT .. "/src/*.h",
}

local LIBUV_FILES_WIN = {
	LIBUV_ROOT .. "/src/win/*.c",
	LIBUV_ROOT .. "/src/win/*.h",
}

local LIBUV_FILES_UNIX = {
	LIBUV_ROOT .. "/src/unix/*.c",
	LIBUV_ROOT .. "/src/unix/*.h",
}

if getTargetOS() == "windows" then
	LIBUV_FILES = mergeTables(LIBUV_FILES, LIBUV_FILES_WIN)
else
	LIBUV_FILES = mergeTables(LIBUV_FILES, LIBUV_FILES_UNIX)
end

local LIBUV_DEFINES = {}

function projectExtraConfig_libuv()
	defines { LIBUV_DEFINES }
	includedirs { LIBUV_ROOT .. "/include" }
	includedirs { LIBUV_ROOT .. "/src" }
end

function projectAdd_libuv()
	addProject_3rdParty_lib("libuv", LIBUV_FILES)
end

function projectSource_libuv()
	return "https://github.com/libuv/libuv.git"
end
