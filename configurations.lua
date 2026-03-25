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
local COPY_QT_DLLS		= WITH_QT
local qtAddedFiles		= {}

-- Extra configuration flags and defines for different configurations
local function setSubConfig(_platform, _configuration, _is64bit, _index)

	local projName = project().name

	commonConfig(_platform, _configuration, _is64bit)

	shaderConfigure(_platform, _configuration, projName)

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
										QT_LIBS_TO_LINK, COPY_QT_DLLS, _is64bit, prefix, _index == 0)
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

vpaths {
	{ ["shaders"]			= "**.sc" },
	{ ["include"]			= { "**.h", "**.hpp", "**.hxx", "**.inl" } },
	{ ["src"]				= { "**.c", "**.cc", "**.cxx", "**.cpp", "src/**.h", "src/**.hpp", "src/**.hxx", "src/**.inl" } },
	{ ["qt/generated/ui"]	= "**_ui.h" },
	{ ["qt/generated/moc"]	= "**_moc.cpp" },
	{ ["qt/generated/qrc"]	= "**_qrc.cpp" },
	{ ["qt/translation"]	= "**.ts" },
	{ ["qt/forms"]			= "**.ui" },
	{ ["qt/resources"]		= "**.qrc" }
}
