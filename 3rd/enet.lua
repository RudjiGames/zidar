--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- ENet reliable UDP networking library
-- https://github.com/lsalzman/enet

local params	= { ... }
local ENET_ROOT	= params[1]

local ENET_FILES = {
	ENET_ROOT .. "/**h",
	ENET_ROOT .. "/**.c"
}

function projectExtraConfig_enet()
	includedirs { ENET_ROOT .. "/include/" }
end

function projectAdd_enet()
	addProject_3rdParty_lib("enet", ENET_FILES)
end


function projectSource_enet()
	return "https://github.com/lsalzman/enet"
end
