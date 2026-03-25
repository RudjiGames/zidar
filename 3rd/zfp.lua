--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Compressed numerical arrays that support high-speed random access
-- https://github.com/LLNL/zfp.git

local params		= { ... }
local ZFP_ROOT	= params[1]

local ZFP_INCLUDE	= {
	ZFP_ROOT .. "/include",
	ZFP_ROOT .. "/src"
}

local ZFP_FILES = {
	ZFP_ROOT .. "/include/**.h",
	ZFP_ROOT .. "/src/*.c",
	ZFP_ROOT .. "/src/*.h"
}

function projectExtraConfig_zfp()
	includedirs { ZFP_INCLUDE }
end

function projectAdd_zfp()
	addProject_3rdParty_lib("zfp", ZFP_FILES)
end

function projectSource_zfp()
	return "https://github.com/LLNL/zfp.git"
end
