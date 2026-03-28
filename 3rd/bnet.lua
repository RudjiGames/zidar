--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Message oriented networking library using TCP transport
-- https://github.com/bkaradzic/bnet

local params	    	= { ... }
local BNET_ROOT	    	= params[1]

local BNET_INCLUDE	= {
	BNET_ROOT .. "/include",
	BNET_ROOT .. "/3rdparty",
	projectGetPath("bx") .. "/include"
}

local BNET_FILES = {
	BNET_ROOT .. "/include/**.h",
	BNET_ROOT .. "/src/**.h",
    BNET_ROOT .. "/src/**.cpp",
} 

function projectDependencies_bnet()
	if os.is("windows") then
		return { "Ws2_32", "Mswsock", "AdvApi32", "bx" }
	end
	return { "bx" }
end 

function projectExtraConfig_bnet()
	if os.is("windows") then
		links { "Ws2_32.lib", "Mswsock.lib", "AdvApi32.lib" }
	end
	includedirs { BNET_INCLUDE }
end

function projectAdd_bnet()
	addProject_3rdParty_lib("bnet", BNET_FILES)
end


function projectSource_bnet()
	return "https://github.com/bkaradzic/bnet"
end
