--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- oneAPI Threading Building Blocks (oneTBB)
-- https://github.com/01org/tbb

local params		= { ... }
local TBB_ROOT		= params[1]

local TBB_INC  		= TBB_ROOT .. "/include/"
local TBB_SRC 		= TBB_ROOT .. "/src/"

local TBB_FILES = {
	TBB_INC .. "**h",
	TBB_SRC .. "tbb/**.cpp",
	TBB_SRC .. "tbb/**.h",
--	TBB_SRC .. "tbbmalloc/**.cpp",
--	TBB_SRC .. "tbbmalloc/**.h",
--	TBB_SRC .. "rml/**.cpp",
--	TBB_SRC .. "rml/**.h"
}

local TBB_INCLUDES = {
	TBB_INC,
	TBB_SRC,
	TBB_SRC .. "test/",
	TBB_SRC .. "rml/include/"
}

local TBB_DEFINES = {
	"__TBB_PERF_API=",
	"TBB_PREVIEW_GLOBAL_CONTROL=1"
}

function projectExtraConfig_tbb()
	forcedincludes {"algorithm"}	-- min/max
	includedirs { TBB_ROOT .. "/build/vs2013/" }
	if getTargetOS() == "windows" then
		defines { "USE_WINTHREAD=1" }
	else
		defines { "USE_PTHREAD=1" }
	end
	defines { TBB_DEFINES }
	includedirs { TBB_INCLUDES }
end 

function projectAdd_tbb()
	addProject_3rdParty_lib("tbb", TBB_FILES)
end


function projectSource_tbb()
	return "https://github.com/01org/tbb"
end
