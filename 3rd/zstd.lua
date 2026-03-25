--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Zstandard - Fast real-time compression algorithm
-- https://github.com/facebook/zstd.git

local params		= { ... }
local ZSTD_ROOT		= params[1]

local ZSTD_FILES = {
	ZSTD_ROOT .. "/lib/common/**.c",
	ZSTD_ROOT .. "/lib/compress/**.h",
	ZSTD_ROOT .. "/lib/decompress/**.c",
	ZSTD_ROOT .. "/lib/decompress/**.h",
	ZSTD_ROOT .. "/lib/dictBuilder/**.c",
	ZSTD_ROOT .. "/lib/dictBuilder/**.h",
	ZSTD_ROOT .. "/lib/*.c",
	ZSTD_ROOT .. "/lib/*.h",
	ZSTD_ROOT .. "/include/**.h"
}

function projectExtraConfig_zstd()
	includedirs { ZSTD_ROOT .. "/lib" }
end

function projectExtraConfigExecutable_zstd()
	includedirs {
		ZSTD_ROOT .. "/lib",
		ZSTD_ROOT .. "/lib/common"
	}
end

function projectAdd_zstd()
	addProject_3rdParty_lib("zstd", ZSTD_FILES)
end

function projectSource_zstd()
	return "https://github.com/facebook/zstd.git"
end
