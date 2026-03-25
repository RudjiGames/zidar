--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Open source DXT compression library
-- https://github.com/Cavewhere/squish.git

local params		= { ... }
local SQUISH_ROOT = params[1]

local SQUISH_FILES = {
	SQUISH_ROOT .. "/*.cpp",
	SQUISH_ROOT .. "/*.h"
}

function projectExtraConfig_squish()
	includedirs { SQUISH_ROOT }
end

function projectAdd_squish()
	addProject_3rdParty_lib("squish", SQUISH_FILES)
end


function projectSource_squish()
	return "https://github.com/Cavewhere/squish.git"
end
