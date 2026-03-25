--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- FreeType font rendering library
-- https://github.com/milostosic/freetype2

local params			= { ... }
local FREETYPE2_ROOT	= params[1]

local FREETYPE2_FILES = {
	FREETYPE2_ROOT .. "/src/autofit/autofit.c",
	FREETYPE2_ROOT .. "/src/base/ftbase.c",
	FREETYPE2_ROOT .. "/src/base/ftbbox.c",
	FREETYPE2_ROOT .. "/src/base/ftbdf.c",
	FREETYPE2_ROOT .. "/src/base/ftbitmap.c",
	FREETYPE2_ROOT .. "/src/base/ftcid.c",
	FREETYPE2_ROOT .. "/src/base/ftfstype.c",
	FREETYPE2_ROOT .. "/src/base/ftgasp.c",
	FREETYPE2_ROOT .. "/src/base/ftglyph.c",
	FREETYPE2_ROOT .. "/src/base/ftgxval.c",
	FREETYPE2_ROOT .. "/src/base/ftinit.c",
	FREETYPE2_ROOT .. "/src/base/ftmm.c",
	FREETYPE2_ROOT .. "/src/base/ftotval.c",
	FREETYPE2_ROOT .. "/src/base/ftpatent.c",
	FREETYPE2_ROOT .. "/src/base/ftpfr.c",
	FREETYPE2_ROOT .. "/src/base/ftstroke.c",
	FREETYPE2_ROOT .. "/src/base/ftsynth.c",
	FREETYPE2_ROOT .. "/src/base/fttype1.c",
	FREETYPE2_ROOT .. "/src/base/ftwinfnt.c",
	FREETYPE2_ROOT .. "/src/bdf/bdf.c",
	FREETYPE2_ROOT .. "/src/bzip2/ftbzip2.c",
	FREETYPE2_ROOT .. "/src/cache/ftcache.c",
	FREETYPE2_ROOT .. "/src/cff/cff.c",
	FREETYPE2_ROOT .. "/src/cid/type1cid.c",
	FREETYPE2_ROOT .. "/src/gzip/ftgzip.c",
	FREETYPE2_ROOT .. "/src/lzw/ftlzw.c",
	FREETYPE2_ROOT .. "/src/pcf/pcf.c",
	FREETYPE2_ROOT .. "/src/pfr/pfr.c",
	FREETYPE2_ROOT .. "/src/psaux/psaux.c",
	FREETYPE2_ROOT .. "/src/pshinter/pshinter.c",
	FREETYPE2_ROOT .. "/src/psnames/psnames.c",
	FREETYPE2_ROOT .. "/src/raster/raster.c",
	FREETYPE2_ROOT .. "/src/sdf/sdf.c",
	FREETYPE2_ROOT .. "/src/sfnt/sfnt.c",
	FREETYPE2_ROOT .. "/src/smooth/smooth.c",
	FREETYPE2_ROOT .. "/src/svg/svg.c",
	FREETYPE2_ROOT .. "/src/truetype/truetype.c",
	FREETYPE2_ROOT .. "/src/type1/type1.c",
	FREETYPE2_ROOT .. "/src/type42/type42.c",
	FREETYPE2_ROOT .. "/src/winfonts/winfnt.c"
}

local added = false
if getTargetOS() == "windows" then
	added = true
	table.insert(FREETYPE2_FILES, FREETYPE2_ROOT .. "/builds/windows/ftsystem.c")
	table.insert(FREETYPE2_FILES, FREETYPE2_ROOT .. "/builds/windows/ftdebug.c")
end

if not added then
	table.insert(FREETYPE2_FILES, FREETYPE2_ROOT .. "/src/base/ftsystem.c")
	table.insert(FREETYPE2_FILES, FREETYPE2_ROOT .. "/src/base/ftdebug.c")
end

function projectExtraConfig_freetype2()
	defines { "FT2_BUILD_LIBRARY" }

	includedirs { FREETYPE2_ROOT .. "/include"}

 	configuration { "vs*", "windows" }	
		buildoptions { "/wd4267" } -- 4267 - conversion from '' to '', possible loss of data
		buildoptions { "/wd4244" } -- 4244 - conversion from '' to '', possible loss of data
 	configuration {}	
end

function projectAdd_freetype2()
	addProject_3rdParty_lib("freetype2", FREETYPE2_FILES)
end

function projectSource_freetype2()
	return "https://github.com/milostosic/freetype2"
end
