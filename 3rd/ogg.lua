--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Reference implementation of the Ogg media container
-- https://github.com/xiph/ogg

local params	= { ... }
local OGG_ROOT	= params[1]

local OGG_FILES = {
	OGG_ROOT .. "/src/**.c",
	OGG_ROOT .. "/src/**.h"
}

function projectDependencies_ogg()
	return {}
end

function projectExtraConfig_ogg()
	includedirs { OGG_ROOT .. "/include" }
end

function projectExtraConfigExecutable_ogg()
	includedirs { OGG_ROOT .. "/include" }
end

function projectAdd_ogg()
	addProject_3rdParty_lib("ogg", OGG_FILES)
end

function projectSource_ogg()
	return "https://github.com/xiph/ogg"
end
