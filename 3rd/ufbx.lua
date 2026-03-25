--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Single source file FBX loader
-- https://github.com/ufbx/ufbx.git

local params		= { ... }
local UFBX_ROOT		= params[1]

local UFBX_FILES = {
	UFBX_ROOT .. "/ufbx.c",
	UFBX_ROOT .. "/ufbx.h",
}

function projectExtraConfig_ufbx()
	includedirs { UFBX_ROOT .. "/Include" }
end

function projectAdd_ufbx()
	addProject_3rdParty_lib("ufbx", UFBX_FILES)
end

function projectSource_ufbx()
	return "https://github.com/ufbx/ufbx.git"
end
