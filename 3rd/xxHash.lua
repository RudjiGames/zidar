--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Extremely fast non-cryptographic hash algorithm
-- https://github.com/Cyan4973/xxHash.git

local params		= { ... }
local XXHASH_ROOT	= params[1]

local XXHASH_INCLUDE	= {
	XXHASH_ROOT
}

local XXHASH_FILES = {
	XXHASH_ROOT .. "/xxh3.h",
	XXHASH_ROOT .. "/xxhash*.c",
	XXHASH_ROOT .. "/xxhash*.h"
}

function projectExtraConfig_xxHash()
	includedirs { XXHASH_INCLUDE }

	configuration { "vs*", "windows" }
			-- 4113 -  incompatible function pointer cast
			buildoptions { "/wd4113"}
	configuration {}
end

function projectAdd_xxHash()
	addProject_3rdParty_lib("xxHash", XXHASH_FILES)
end

function projectSource_xxHash()
	return "https://github.com/Cyan4973/xxHash.git"
end
