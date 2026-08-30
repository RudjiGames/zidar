--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

local params = { ... }

local WITH_QT			= params[1] or false
local QT_FILES_MOC		= params[2] or {}
local QT_FILES_UI		= params[3] or {}
local QT_FILES_QRC		= params[4] or {}
local QT_FILES_TS		= params[5] or {}
local QT_LIBS_TO_LINK	= params[6] or {}
local QT_COPY_ONLY_DLLS	= params[7] or {}	-- runtime-only Qt DLLs: copied next to the exe but not linked
local COPY_QT_DLLS		= WITH_QT
local qtAddedFiles		= {}

-- Extra configuration flags and defines for different configurations
local function setSubConfig(_platform, _configuration, _is64bit, _index)

	local projName = project().name

	commonConfig(_platform, _configuration, _is64bit)

	local prefix = ""
	if _configuration == "debug" then
		prefix = "d"
	end

	if WITH_QT then
        configuration { _configuration }
		-- _index == 0 checks we add files only once, not for every configuration, since they are the same for all configs
        local addedFiles = qtConfigure( _platform, _configuration,
										QT_FILES_MOC,
										QT_FILES_UI,
										QT_FILES_QRC,
										QT_FILES_TS,
										QT_LIBS_TO_LINK, COPY_QT_DLLS, _is64bit, prefix, _index == 0, QT_COPY_ONLY_DLLS)
		if _index == 0 then
			qtAddedFiles = addedFiles
		end
	end
	local extraConfigFn = _G["projectExtraConfig_" .. projName]
	if extraConfigFn then
		extraConfigFn()
	end
end

-- This function is called from projects after they set up their files and before adding dependencies
-- adding extra defines, flags or linking extra libraries based on project type
local function setConfig(_configuration)
	local index = 0
	local currPlatforms = platforms()
	for _,platform in ipairs(currPlatforms) do
		setSubConfig(platform, _configuration, "x64" == platform, index)
		index = index + 1
	end
end

configuration {}
local all_configs = configurations()
for _,config in ipairs(all_configs) do
	configuration { config }
		targetsuffix ("_" .. config)
		defines { ExtraDefines[config] }
		flags   { ExtraFlags[config] }
	setConfig(config)
end
configuration {}

-- NoRTTI under clang-cl (vs*-clang): GENie emits <RuntimeTypeInfo>false</RuntimeTypeInfo>, which MSBuild's ClangCL
-- toolset turns into /GR-. On MSVC, /GR- undefines __cpp_rtti, so RTTI-conditional code (Qt's assertObjectType in
-- qobjectdefs_impl.h, run on EVERY slot dispatch when Q_ASSERT is live) takes its non-RTTI branch. clang-cl maps
-- /GR- to -fno-rtti-data instead: __cpp_rtti stays DEFINED, dynamic_cast still compiles, but no complete-object
-- locators are emitted - so the first dynamic_cast on one of our vtables crashes inside __RTDynamicCast /
-- FindCompleteObject (observed: StartPageWidget ctor, first connect() fired). clang warns about exactly this
-- (-Wrtti: "dynamic_cast will not work since RTTI data is disabled by /GR-") - never suppress that warning.
-- Passing -fno-rtti restores MSVC parity (__cpp_rtti and _CPPRTTI both undefined, dynamic_cast/typeid become hard
-- errors instead of silent crashes). Applied ONLY to projects whose flag table carries NoRTTI, so vendored code on
-- Flags_ThirdParty (RTTI on, as under MSVC) is untouched. The gmake clang/gcc paths already emit -fno-rtti natively.
if _OPTIONS["vs"] and string.find(_OPTIONS["vs"], "-clang", 1, true) then
	local blk = project().blocks[1]
	if blk and blk.flags and table.contains(blk.flags, "NoRTTI") then
		buildoptions { "/clang:-fno-rtti" }
	end
end

-- Regenerate embedded-shader headers once per project (config/platform neutral).
shaderConfigure(project().name)

-- IDE virtual paths, resolved first-match-wins (see orderedVpaths in toolchain.lua),
-- so the specific patterns (Qt generated files, private headers in src/) must come
-- before the "include"/"src" catch-alls.
orderedVpaths {
	{ ["shaders"]			= "**.sc" },
	{ ["qt/generated/ui"]	= "**_ui.h" },
	{ ["qt/generated/moc"]	= "**_moc.cpp" },
	{ ["qt/generated/qrc"]	= "**_qrc.cpp" },
	{ ["qt/generated/qm"]	= "**.qm" },
	{ ["qt/translation"]	= "**.ts" },
	{ ["qt/forms"]			= "**.ui" },
	{ ["qt/resources"]		= "**.qrc" },
	{ ["src"]				= { "src/**.h", "src/**.hpp", "src/**.hxx", "src/**.inl" } },
	{ ["include"]			= { "**.h", "**.hpp", "**.hxx", "**.inl" } },
	{ ["src"]				= { "**.c", "**.cc", "**.cxx", "**.cpp", "**.m", "**.mm", "**.rc" } }
}
