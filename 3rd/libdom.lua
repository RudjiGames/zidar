--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- LibDOM - an implementation of the W3C DOM
-- https://github.com/netsurf-plan9/libdom.git

local params		= { ... }
local LIBDOM_ROOT	= params[1]

local LIBDOM_FILES = {
	LIBDOM_ROOT .. "/bindings/xml/libxml_xmlparser.c",
	LIBDOM_ROOT .. "/src/**.c",
	LIBDOM_ROOT .. "/src/**.h",
}

function projectDependencies_libdom()
	return { "libwapcaplet", "libparserutils", "libxml2" }
end 

function projectDependencyConfig_libdom()
	if getTargetOS() == "windows" then
		links { "Bcrypt" }
	end
	includedirs { LIBDOM_ROOT .. "/include",
				  LIBDOM_ROOT .. "/include/dom" }
end

function projectExtraConfig_libdom()
	defines {"PRIu32="}
	includedirs { LIBDOM_ROOT .. "/src",
				  LIBDOM_ROOT .. "/include",
				  LIBDOM_ROOT .. "/include/dom" }
end

function projectAdd_libdom()
	addProject_3rdParty_lib("libdom", LIBDOM_FILES)
end

function projectSource_libdom()
	return "https://github.com/netsurf-plan9/libdom.git"
end
