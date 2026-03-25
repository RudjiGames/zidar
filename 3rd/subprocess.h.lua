--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Single header process launching solution for C and C++
-- https://github.com/sheredom/subprocess.h

local params	= { ... }
local SUBP_ROOT	= params[1]

local SUBP_FILES = {
	SUBP_ROOT .. "/subprocess.h",
}

function projectExtraConfig_subprocess_h()
	includedirs { SUBP_ROOT .. "/include/" }
end

function projectHeaderOnlyLib_subprocess_h()
end

function projectAdd_subprocess_h()
	addProject_3rdParty_lib("subprocess_h", SUBP_FILES)
end

function projectSource_subprocess_h()
	return "https://github.com/sheredom/subprocess.h"
end
