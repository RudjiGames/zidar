--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

module("assimp", package.seeall)

-- Open-Asset-Importer-Library, loads 40+ 3D-file-formats
-- https://github.com/assimp/assimp

local params		= { ... }
local ASSIMP_ROOT	= params[1]

local ASSIMP_FILES = {
	ASSIMP_ROOT .. "/code/**.cpp",
	ASSIMP_ROOT .. "/code/**.h",
	ASSIMP_ROOT .. "/include/**.h",
	ASSIMP_ROOT .. "/include/**.inl",
	ASSIMP_ROOT .. "/include/**.hpp",
	ASSIMP_ROOT .. "/contrib/clipper/**.h",
	ASSIMP_ROOT .. "/contrib/clipper/**.cpp",
	ASSIMP_ROOT .. "/contrib/ConvertUTF/**.h",
	ASSIMP_ROOT .. "/contrib/ConvertUTF/**.c",
	ASSIMP_ROOT .. "/contrib/irrXML/**.h",
	ASSIMP_ROOT .. "/contrib/irrXML/**.cpp",
	ASSIMP_ROOT .. "/contrib/poly2tri/poly2tri/**.h",
	ASSIMP_ROOT .. "/contrib/poly2tri/poly2tri/**.cc",
	ASSIMP_ROOT .. "/contrib/unzip/**.h",
	ASSIMP_ROOT .. "/contrib/unzip/**.c",
	ASSIMP_ROOT .. "/contrib/zlib/*.h",
	ASSIMP_ROOT .. "/contrib/zlib/*.c",
	ASSIMP_ROOT .. "/contrib/openddlparser/**.*"
}

local ASSIMP_INCLUDES = {
	ASSIMP_ROOT,
	ASSIMP_ROOT .. "/include/",	
	ASSIMP_ROOT .. "/contrib/",
	ASSIMP_ROOT .. "/contrib/rapidjson/include/",
	ASSIMP_ROOT .. "/contrib/irrXML/",
	ASSIMP_ROOT .. "/contrib/openddlparser/include/",
	ASSIMP_ROOT .. "/contrib/zlib/",
	ASSIMP_ROOT .. "/contrib/zlib/contrib/minizip",
	ASSIMP_ROOT .. "/contrib/utf8cpp/source",
	ASSIMP_ROOT .. "/code/BoostWorkaround/",
	ASSIMP_ROOT .. "/code/",
	ASSIMP_ROOT .. "/contrib/pugixml/src"
}

function projectExtraConfig_assimp()
	includedirs { ASSIMP_INCLUDES }
	defines {"ASSIMP_BUILD_NO_IFC_IMPORTER", "ASSIMP_BUILD_NO_C4D_IMPORTER", "ASSIMP_BUILD_NO_EXPORT", "OPENDDL_STATIC_LIBARY" }

	configuration { "vs20*", "not orbis", "not durango", "not winphone*", "not winstore*" }
		buildoptions { "/bigobj" }
	
	configuration {}
end 

-- disable IFC importer as it fails to compile with TDM-GCC 4.8.1
function projectAdd_assimp()
	if os.is("windows") then
		os.execute(string.gsub("copy " .. ASSIMP_ROOT .. "/include/assimp/config.h.in " .. ASSIMP_ROOT .. "/include/assimp/config.h", "/", "\\"))
		os.execute("sed -i s/" .. '"cmakedefine ASSIMP_DOUBLE_PRECISION"' .. "/" .. '"define ASSIMP_FUCK_DOUBLE_PRECISION"' .. "/g " .. string.gsub(ASSIMP_ROOT .. "/include/assimp/config.h", "/", "\\"))
		os.execute(string.gsub("copy " .. ASSIMP_ROOT .. "/revision.h.in " .. ASSIMP_ROOT .. "/code/revision.h", "/", "\\"))
		os.execute("sed -i s/0x@GIT_COMMIT_HASH@/0/g " .. string.gsub(ASSIMP_ROOT .. "/code/revision.h", "/", "\\"))
		os.execute("sed -i s/@ASSIMP_VERSION_MAJOR@/1/g " .. string.gsub(ASSIMP_ROOT .. "/code/revision.h", "/", "\\"))
		os.execute("sed -i s/@ASSIMP_VERSION_MINOR@/0/g " .. string.gsub(ASSIMP_ROOT .. "/code/revision.h", "/", "\\"))
		os.execute("sed -i s/@ASSIMP_VERSION_PATCH@/0/g " .. string.gsub(ASSIMP_ROOT .. "/code/revision.h", "/", "\\"))
		os.execute("sed -i s/@ASSIMP_PACKAGE_VERSION@/1/g " .. string.gsub(ASSIMP_ROOT .. "/code/revision.h", "/", "\\"))

		os.execute(string.gsub("copy " .. ASSIMP_ROOT .. "/contrib/zlib/zconf.h.included " .. ASSIMP_ROOT .. "/contrib/zlib/zconf.h", "/", "\\"))
	else
		os.execute("cp " .. ASSIMP_ROOT .. "/include/assimp/config.h.in " ..  ASSIMP_ROOT .. "/include/assimp/config.h")
		os.execute("sed -i '' -e s/" .. '"cmakedefine ASSIMP_DOUBLE_PRECISION"' .. "/" .. '"define ASSIMP_FUCK_DOUBLE_PRECISION"' .. "/g " .. ASSIMP_ROOT .. "/include/assimp/config.h")
		os.execute("cp " .. ASSIMP_ROOT .. "/revision.h.in " .. ASSIMP_ROOT .. "/code/revision.h")
		os.execute("sed -i '' -e s/0x@GIT_COMMIT_HASH@/0/g " .. ASSIMP_ROOT .. "/code/revision.h")
		os.execute("sed -i '' -e s/@ASSIMP_VERSION_MAJOR@/0/g " .. ASSIMP_ROOT .. "/code/revision.h")
		os.execute("sed -i '' -e s/@ASSIMP_VERSION_MINOR@/0/g " .. ASSIMP_ROOT .. "/code/revision.h")
		os.execute("sed -i '' -e s/@ASSIMP_VERSION_PATCH@/0/g " .. ASSIMP_ROOT .. "/code/revision.h")
		os.execute("sed -i '' -e s/@ASSIMP_PACKAGE_VERSION@/0/g " .. ASSIMP_ROOT .. "/code/revision.h")

		os.execute("cp " .. ASSIMP_ROOT .. "/contrib/zlib/zconf.h.included " .. ASSIMP_ROOT .. "/contrib/zlib/zconf.h")
	end

	addProject_3rdParty_lib("assimp", ASSIMP_FILES, true)
end

function projectSource_assimp()
	return "https://github.com/assimp/assimp"
end
