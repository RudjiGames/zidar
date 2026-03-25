--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- MSDF font atlas generator
-- https://github.com/Chlumsky/msdf-atlas-gen.git

local params			= { ... }
local MSDFATLASGEN_ROOT	= params[1]

local MSDFATLASGEN_FILES = {
	MSDFATLASGEN_ROOT .. "/msdf-atlas-gen/**.cpp",
	MSDFATLASGEN_ROOT .. "/msdf-atlas-gen/**.hpp",
	MSDFATLASGEN_ROOT .. "/msdf-atlas-gen/**.h",
	MSDFATLASGEN_ROOT .. "/msdfgen/**.cpp",
	MSDFATLASGEN_ROOT .. "/msdfgen/**.hpp",
	MSDFATLASGEN_ROOT .. "/msdfgen/**.h"
}

function projectDependencyConfig_msdf_atlas_gen()
	includedirs {
		MSDFATLASGEN_ROOT,
		MSDFATLASGEN_ROOT .. "/msdfgen",
	--	MSDFATLASGEN_ROOT .. "/artery-font-format"		
	}
	defines { "MSDFGEN_PUBLIC= " } -- static link
end

function projectExtraConfig_msdf_atlas_gen()

	projectDependencyConfig_msdf_atlas_gen()
	includedirs {
		--MSDFATLASGEN_ROOT,
		--MSDFATLASGEN_ROOT .. "/msdfgen",
		MSDFATLASGEN_ROOT .. "/artery-font-format"		
	}
	defines { "MSDFGEN_PUBLIC= " } -- static link

 	configuration { "vs*", "windows" }
		buildoptions { "/wd4005" } -- 4005 - '_CRT_SECURE_NO_WARNINGS': macro redefinition
		buildoptions { "/wd4100" } -- 4100 - '': unreferenced parameter
		buildoptions { "/wd4458" } -- 4458 - declaration of 'p' hides class member
		buildoptions { "/wd4244" } -- 4244 - 'argument': conversion from '' to '', possible loss of data
		buildoptions { "/wd4267" } -- 4267 - 'argument': conversion from '' to '', possible loss of data
		buildoptions { "/wd4706" } -- 4706 - assignment used as a condition
		buildoptions { "/wd4505" } -- 4505 - '': unreferenced function with internal linkage has been removed
		buildoptions { "/wd4127" } -- 4127 - conditional expression is constant
		buildoptions { "/wd4457" } -- 4457 - declaration of '' hides function parameter
		buildoptions { "/wd4456" } -- 4456 - declaration of '' hides previous local declaration
 	configuration {}	
end

function projectDependencies_msdf_atlas_gen()
	return { "freetype2", "tinyxml2" }
end 

function projectAdd_msdf_atlas_gen()
	addProject_3rdParty_lib("msdf_atlas_gen", MSDFATLASGEN_FILES)
end

function projectSource_msdf_atlas_gen()
	return "https://github.com/Chlumsky/msdf-atlas-gen.git"
end
