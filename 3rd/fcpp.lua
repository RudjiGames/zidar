--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Frexx C preprocessor
-- https://github.com/bagder/fcpp

local params	= { ... } 
local FCPP_ROOT = params[1]

local FCPP_FILES = {
	FCPP_ROOT .. "/cpp1.c",
	FCPP_ROOT .. "/cpp2.c",
	FCPP_ROOT .. "/cpp3.c",
	FCPP_ROOT .. "/cpp4.c",
	FCPP_ROOT .. "/cpp5.c",
	FCPP_ROOT .. "/cpp6.c",
	FCPP_ROOT .. "/fpp.h",
	FCPP_ROOT .. "/fppadd.h",
	FCPP_ROOT .. "/fppdef.h",
	FCPP_ROOT .. "/fpp.h",
	FCPP_ROOT .. "/FPPBase.h",
	FCPP_ROOT .. "/fpp_pragmas.h",
	FCPP_ROOT .. "/FPP_protos.h"
}

function projectAdd_fcpp()
	addProject_3rdParty_lib("fcpp", FCPP_FILES)
end


function projectSource_fcpp()
	return "https://github.com/bagder/fcpp"
end
