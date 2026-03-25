--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- XML parser and toolkit
-- https://github.com/GNOME/libxml2.git

local params		= { ... }
local LIBXML2_ROOT	= params[1]

local LIBXML2_FILES = {
	LIBXML2_ROOT .. "/*.c",
	LIBXML2_ROOT .. "/*.h",
}

function setupCMakeProjectHeaders(srcPath, dstPath, replacePairs)
	-- replace cmakedefine with define
	-- replace strings with known values
	-- remove all instances of '@'

	os.copyfile(srcPath, dstPath);

	if replacePairs ~= nil then
    for _,replacePair in ipairs(replacePairs) do
		os.execute("sed -i s/'" .. replacePair[1] .. "'/'" .. replacePair[2] .. "'/g " .. dstPath)
	end
	end

	os.execute("sed -i s/cmakedefine/define/g " .. dstPath)
	os.execute("sed -i s/@//g " .. dstPath)
end

function projectDependencies_libxml2()
	return { "zlib" }
end 

function projectDependencyConfig_libxml2()
	defines {	"WITH_ZLIB",
				"LIBXML_SCHEMAS_ENABLED",
				"LIBXML_REGEXP_ENABLED",
				"LIBXML_AUTOMATA_ENABLED",
				"LIBXML_PATTERN_ENABLED",
				"LIBXML_VALID_ENABLED",
				"LIBXML_STATIC",
				"LIBXML_UNICODE_ENABLED",
				"LIBXML_PUSH_ENABLED"
	}
	includedirs { LIBXML2_ROOT .. "/include" }
end

function projectExtraConfig_libxml2()
	projectDependencyConfig_libxml2()
	excludes {	LIBXML2_ROOT .. "/test*.c",
				LIBXML2_ROOT .. "/run*.c",
				LIBXML2_ROOT .. "/xmlcatalog.c",
				LIBXML2_ROOT .. "/xmllint.c"
	}
end

function projectAdd_libxml2()

	local replaceConfig = {
		{ "HAVE_LIBHISTORY 1",			"HAVE_LIBHISTORY 0" },
		{ "HAVE_LIBREADLINE 1",			"HAVE_LIBREADLINE_UNDEF 0" },
		{ "HAVE_SYS_TIME_H 1",			"HAVE_SYS_TIME_H_UNDEF 0" },
		{ "HAVE_UNISTD_H 1",			"HAVE_UNISTD_H_UNDEF 0" },
		{ "HAVE_SYS_MMAN_H 1",			"HAVE_SYS_MMAN_H_UNDEF 0" },
		{ "HAVE_MMAP 1",				"HAVE_MMAP_H_UNDEF 0" },
		{ "HAVE_GETTIMEOFDAY 1",		"HAVE_GETTIMEOFDAY_UNDEF 0" },
		{ "HAVE_SYS_TIMEB_H 1",			"HAVE_SYS_TIMEB_H_UNDEF 0" }
	}

	local replaceXMLver = {
		{ "@VERSION@",					"1.2.3" },
		{ "@LIBXML_VERSION_NUMBER@",	"10203" }
	}

	setupCMakeProjectHeaders(LIBXML2_ROOT .. "/config.h.cmake.in", LIBXML2_ROOT .. "/config.h", replaceConfig)
	setupCMakeProjectHeaders(LIBXML2_ROOT .. "/include/libxml/xmlversion.h.in", LIBXML2_ROOT .. "/include/libxml/xmlversion.h", replaceXMLver)

	addProject_3rdParty_lib("libxml2", LIBXML2_FILES)
end

function projectSource_libxml2()
	return "https://github.com/GNOME/libxml2.git"
end
