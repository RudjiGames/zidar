--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Technical analysis library
-- https://github.com/milostosic/ta-lib

local params		= { ... }
local TA_LIB_ROOT	= params[1]

local TA_LIB_FILES = {
	TA_LIB_ROOT .. "/src/ta_common/**h",
	TA_LIB_ROOT .. "/src/ta_common/**.c",
	TA_LIB_ROOT .. "/src/ta_func/**h",
	TA_LIB_ROOT .. "/src/ta_func/**.c",
}

local TA_LIB_INCLUDES = { 
	TA_LIB_ROOT .. "/include/",
	TA_LIB_ROOT .. "/src/ta_common/" 
}

function projectExtraConfig_ta_lib()
	includedirs { TA_LIB_INCLUDES }
end

function projectAdd_ta_lib()
	addProject_3rdParty_lib("ta_lib", TA_LIB_FILES)
end


function projectSource_ta_lib()
	return "https://github.com/milostosic/ta-lib"
end
