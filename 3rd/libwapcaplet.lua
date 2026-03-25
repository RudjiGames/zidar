--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- LibDOM - an implementation of the W3C DOM
-- https://github.com/netsurf-plan9/libdom.git

local params		= { ... }
local LIBWAP_ROOT	= params[1]

local LIBWAP_FILES = {
	LIBWAP_ROOT .. "/src/**.c",
}

function projectDependencyConfig_libwapcaplet()
	includedirs { LIBWAP_ROOT .. "/include" }
end

function projectExtraConfig_libwapcaplet()
	projectDependencyConfig_libwapcaplet()
end

function projectAdd_libwapcaplet()
	addProject_3rdParty_lib("libwapcaplet", LIBWAP_FILES)
end

function projectSource_libwapcaplet()
	return "https://github.com/netsurf-plan9/libdom.git"
end
