--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

--------------------------------------------------------
-- options
--------------------------------------------------------

newoption {
	trigger			= "with-unittests",
	description		= "Generates library unit test projects"
}

newoption {
	trigger			= "with-tools",
	description		= "Generates library tools projects"
}

newoption {
	trigger			= "with-samples",
	description		= "Generates library sample projects"
}

newoption {
	trigger			= "with-no-pch",
	description		= "Disables precompiled headers for all projects"
}

newoption {
	trigger			= "zidar-path",
	description		= "Path to zidar"
}

--------------------------------------------------------
-- Text coloring
--------------------------------------------------------

Color = {
	Black	= 30,	Red		= 31,	Green	= 32,	
	Yellow	= 33,	Blue	= 34,	Magenta	= 35,	
	Cyan	= 36,	White	= 37,	Default	= 39
}

local _ansiCache = {}

-- Returns ANSI escape code string for the given foreground and background color
function textColorANSI(_color, _background)
	_background = _background or Color.Default
	local key = _color * 256 + _background
	local cached = _ansiCache[key]
	if cached then return cached end
	local bgCode = (_background == Color.Default) and 49 or (_background + 70)
	cached = "\x1b[1;" .. _color .. ";" .. bgCode .. "m"
	_ansiCache[key] = cached
	return cached
end

-- Precomputed ANSI escape codes per color value
textColorANSI(Color.Cyan)
textColorANSI(Color.Green)
textColorANSI(Color.Yellow)
textColorANSI(Color.Red)
textColorANSI(Color.Red, Color.Yellow)
textColorANSI(Color.Default)

-- Wraps a string with ANSI blink escape codes
function textBlink(_string)
	if _string then	return "\x1b[5m" .. _string .. "\x1b[25m" end 
	return nil
end

-- Returns a colored string with optional blink and background color
local _ansiDefault = textColorANSI(Color.Default)
function textColor(_string, _color, _background, _blink)
	if not _string then print(debug.traceback()) end
	local retText = textColorANSI(_color, _background) .. _string .. _ansiDefault
	if _blink then return textBlink(retText) end
	return retText
end

-- Pads or trims a string to exactly 30 characters wide
function textFixedWidth(_s)
	return string.format("%-30s", string.sub(_s, 1, 30))
end

-- Prints an informational message in the given color (defaults to cyan)
function printInfo(_message, _color)
	print(textColor(_message, _color or Color.Cyan))
end

-- Prints a blinking yellow warning message to the console
function printWarning(_message)
	print(textColor("WARNING: ", Color.Yellow, nil, true) .. _message)
end

-- Prints a red error message and terminates the build
function printError(_message, _exit)
	if _exit == nil then _exit = false end
	print(textColor("ERROR:", Color.Red, nil, true) .. " " .. textColor(_message, Color.Yellow))
	disableUTF8()
	if _exit then
		os.exit(1)
	end
end

--------------------------------------------------------
-- Version info
--------------------------------------------------------
Version = {
	High	= '1',
	Low		= '0'
}

-- is running on Windows (cached at load time)
local _isWindows = package.config:sub(1, 1) == '\\'
function isRunningOnWindows()
    return _isWindows
end

RG_CONSOLE_CODE_PAGE_DEFAULT	= 437	-- OEM code page (default for console input/output)
RG_CONSOLE_CODE_PAGE_UTF8		= 65001	-- UTF-8

if isRunningOnWindows() then
	local output = os.outputof("chcp")
	RG_CONSOLE_CODE_PAGE_DEFAULT = tonumber(string.match(output, '%d+'))
end

local _utfEnable  = "@chcp " .. tostring(RG_CONSOLE_CODE_PAGE_UTF8) .. " > nul"
local _utfDisable = "@chcp " .. tostring(RG_CONSOLE_CODE_PAGE_DEFAULT) .. " > nul"

function enableUTF8()
	if isRunningOnWindows() then
		os.execute(_utfEnable)
	end
end

-- restores the original console code page on Windows
function disableUTF8()
	if isRunningOnWindows() then
		os.execute(_utfDisable)
	end
end

--------------------------------------------------------
-- atexit
--------------------------------------------------------

local _exitCallbacks = {}
local _osExit = os.exit

local function _runExitCallbacks()
	for i = #_exitCallbacks, 1, -1 do
		_exitCallbacks[i]()
	end
end

function atexit(func)
	_exitCallbacks[#_exitCallbacks + 1] = func
end

os.exit = function(code)
	_runExitCallbacks()
	_osExit(code)
end

-- ensure callbacks fire after GENie generates output
if premake and premake.action and premake.action.call then
	local _origActionCall = premake.action.call
	premake.action.call = function(name)
		_origActionCall(name)
		_runExitCallbacks()
	end
end

enableUTF8()
print(	textColor("\xE2\x96\x91\xE2\x96\x92\xE2\x96\x93", Color.Green) .. " " ..
		textColor("zidar", Color.Green) ..
		textColor(" v" .. Version.High .. "." .. Version.Low, Color.Green) .. " " ..
		textColor("\xE2\x96\x93\xE2\x96\x92\xE2\x96\x91", Color.Green) )

atexit(function()
    disableUTF8()
end)

--------------------------------------------------------
-- directories and defines
--------------------------------------------------------

function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)") or "./"
end

local function pathGetSeparator()
  if isRunningOnWindows() then
    return '\\'
  end
  return '/'
end

local function zidarPath()                                       
  local str = debug.getinfo(2, 'S').source:sub(2)                  
  if isRunningOnWindows() then                                                 
    str = str:gsub('/', '\\')                                      
  end                                                              
  return str:match('(.*' .. pathGetSeparator() .. ')')           
end

RG_ZIDAR_HOME_DIR	= path.getabsolute(os.getenv("HOME") or os.getenv("HOMEPATH")) 	-- handle Windows and Unix home paths
RG_SCRIPTS_DIR 		= path.getdirectory(script_path())								-- directory of this script
RG_ROOT_DIR			= path.getabsolute(_WORKING_DIR)								-- project root
RG_DEPENDENCY_DIR	= RG_ROOT_DIR .. "/.3rd"										-- For automatically downloaded 3rd party dependencies
RG_LOCATION_PATH	= ""
RG_ZIDAR_DIR		= zidarPath()

if os.isfile(RG_ROOT_DIR .. "/genie.lua") then
	RG_ROOT_DIR = path.getabsolute(path.join(RG_ROOT_DIR, ".."))
end
RG_ZIDAR_BUILD_DIR	= RG_ROOT_DIR .. "/.zidar"										-- temp build files

-- strip trailing slash if present before adding for consistent path handling
while string.sub(RG_ZIDAR_DIR, -1) == "/" or string.sub(RG_ZIDAR_DIR, -1) == "\\" do
	RG_ZIDAR_DIR = string.sub(RG_ZIDAR_DIR, 1, -2)
end
print(textColor("\xE2\x96\xB6", Color.Green) .. textColor(" zidar path :", Color.Cyan) .. "            " .. textColor(RG_ZIDAR_DIR, Color.Green))

--------------------------------------------------------
-- Load zidar scripts
--------------------------------------------------------

dofile (RG_SCRIPTS_DIR .. "/project_3rd.lua")
dofile (RG_SCRIPTS_DIR .. "/project_cmdtool.lua")
dofile (RG_SCRIPTS_DIR .. "/project_game.lua")
dofile (RG_SCRIPTS_DIR .. "/project_lib.lua")
dofile (RG_SCRIPTS_DIR .. "/project_lib_sample.lua")
dofile (RG_SCRIPTS_DIR .. "/project_lib_test.lua")
dofile (RG_SCRIPTS_DIR .. "/project_lib_tool.lua")
dofile (RG_SCRIPTS_DIR .. "/project_qt.lua")
dofile (RG_SCRIPTS_DIR .. "/embedded_files.lua")
dofile (RG_SCRIPTS_DIR .. "/qtpresets6.lua")

projectConfig			= assert(loadfile(RG_SCRIPTS_DIR .. "/configurations.lua"))
projectSetupToolchain	= assert(loadfile(RG_SCRIPTS_DIR .. "/toolchain.lua"))

projectSetupToolchain()

if os.getenv("RG_ZIDAR_DEPENDENCY_DIR") then
	local envdir = path.getabsolute(os.getenv("RG_ZIDAR_DEPENDENCY_DIR"))
	if (os.isdir(envdir)) then
		RG_DEPENDENCY_DIR = envdir
	else
		printError("Environment variable " .. 
					textColor("RG_ZIDAR_DEPENDENCY_DIR", Color.Red) .. textColor(" is set to ", Color.Yellow) .. 
					textColor(envdir, Color.Red) .. textColor(", but it is not a valid directory.", Color.Yellow))

	end	
end 

local QT_PATH = os.getenv("QTDIR")
if QT_PATH ~= nil then
	-- strip trailing slash if present before adding for consistent path handling
	while string.sub(QT_PATH, -1) == "/" or string.sub(QT_PATH, -1) == "\\" do
		QT_PATH = string.sub(QT_PATH, 1, -2)
	end
	print(textColor("\xE2\x96\xB6", Color.Green) .. textColor(" QTDIR :", Color.Cyan) .. "                 " .. textColor(QT_PATH, Color.Green))
end

printInfo(textColor("\xE2\x96\xB6", Color.Green) .. " " .. textColor("Checking environment... ", Color.Cyan) .. textColor("OK!", Color.Green))

if _ACTION == "clean" then
	os.rmdir(RG_ZIDAR_BUILD_DIR)
	if not os.getenv("RG_ZIDAR_DEPENDENCY_DIR") then
		os.rmdir(RG_DEPENDENCY_DIR)
	end 
	os.exit()
	return
end

--------------------------------------------------------
-- compiler flags
--------------------------------------------------------

Flags_ThirdParty		= { "StaticRuntime", "NoEditAndContinue", "NoPCH",  "MinimumWarnings" }
Flags_Libraries			= { "StaticRuntime", "NoEditAndContinue", "NoRTTI", "ExtraWarnings", "NoExceptions" }
Flags_Tests				= { "StaticRuntime", "NoEditAndContinue", "NoRTTI", "ExtraWarnings" }
Flags_Cmd				= { "StaticRuntime", "NoEditAndContinue", "NoRTTI", "ExtraWarnings", "NoExceptions" }
Flags_QtTool			= { "StaticRuntime", "NoEditAndContinue", "NoRTTI", "ExtraWarnings" }

ExtraFlags = {}
ExtraFlags["debug"]		= { "Symbols" }
ExtraFlags["release"]	= { "NoFramePointer", "OptimizeSpeed", "NoBufferSecurityCheck", "Symbols" }
ExtraFlags["retail"]	= { "NoFramePointer", "OptimizeSpeed", "NoBufferSecurityCheck" }

ExtraDefines = {}
ExtraDefines["debug"]   = { "RG_DEBUG_BUILD", "_DEBUG", "DEBUG" }
ExtraDefines["release"] = { "RG_RELEASE_BUILD", "NDEBUG" }
ExtraDefines["retail"]	= { "RG_RETAIL_BUILD", "NDEBUG", "RETAIL" }

--------------------------------------------------------
-- utility functions to check for target compiler
--------------------------------------------------------

-- Returns true if the current action targets Visual Studio
function actionUsesMSVC()
	return (_ACTION ~= nil and _ACTION:find("vs"))
end

-- Returns true if the current action targets Xcode
function actionUsesXcode()
	return (_ACTION ~= nil and _ACTION:find("xcode"))
end

--------------------------------------------------------
-- fixup for precompiled header path
--------------------------------------------------------

-- Configures precompiled header for a project if PCH files exist
function addPCH(_path, _name)

	if _OPTIONS["with-no-pch"] ~= nil then
		return
	end

	 -- do not use PCH on macOS as it causes issues with Xcode
	if os.is("macosx") then 
		return
	end

	local name = projectNameCleanup(_name)
	local fullPath = path.getabsolute(path.join(_path, name))

	-- called once per project, no need to cache results
	if os.isfile(fullPath  .. "_pch.h") then
		if not actionUsesMSVC() then
			pchheader (fullPath  .. "_pch.h")
		else
			pchheader (name  .. "_pch.h")
		end
	else
		printWarning("PCH header file for " .. textColor(name, Color.Cyan) .. " project not found: ".. textColor(fullPath  .. "_pch.h", Color.Blue) )
		return
	end

	local PCHSourceFound = false
	if os.isfile(fullPath .. "_pch.cpp") then
		PCHSourceFound = true
		pchsource (fullPath .. "_pch.cpp")
	end

	if not PCHSourceFound and os.isfile(fullPath .. "_pch.c") then  -- support C projects as well
		PCHSourceFound = true
		pchsource (fullPath .. "_pch.c")
	end

	if not PCHSourceFound then
		printWarning("PCH source file for " .. textColor(name, Color.Cyan) .. " not found!")
	end
end

--------------------------------------------------------
-- 'Enums'
--------------------------------------------------------

LibraryType = {
	Runtime	= {},
	Tool	= {},
	Game	= {}
}

function vpathStringFromLibraryType(_libType)
	if _libType == LibraryType.Tool then
		return "libs_tools"
	elseif _libType == LibraryType.Game then
		return "libs_game"
	else
		return "libs"
	end
end

--------------------------------------------------------
-- Load 3rd party zidar script names
--------------------------------------------------------
RG_3RD_PARTY_SCRIPTS		= {}
RG_3RD_PARTY_SCRIPTS_LOADED	= {}


local rdPartyFiles = os.matchfiles(RG_SCRIPTS_DIR .. "/3rd/*.lua")
for _, file in ipairs(rdPartyFiles) do
	local moduleName = path.getbasename(file)
	RG_3RD_PARTY_SCRIPTS[moduleName] = path.getabsolute(file)
end

--------------------------------------------------------
-- helper functions
--------------------------------------------------------

-- Merges any number of tables into one, removing duplicates
function mergeTables(...)
    local result = {}
    local hash = {}
    local n = 0
    for i = 1, select('#', ...) do
        local t = select(i, ...)
        if t then
            for _,v in ipairs(t) do
                if not hash[v] then
                    n = n + 1
                    result[n] = v
                    hash[v] = true
                end
            end
        end
    end
    return result
end
--------------------------------------------------------
-- Prerequisites
--------------------------------------------------------
printInfo(textColor("\xE2\x96\xB6", Color.Green) .. " " .. textColor("Checking tools...       ", Color.Cyan) .. textColor("OK!", Color.Green))

-- Verifies a required tool is available in PATH, exits with error if not
local _pathEnv = os.getenv("PATH") or ""
function checkPrerequisite(_toolName)
	local exeName = isRunningOnWindows() and (_toolName .. ".exe") or _toolName
	if not os.pathsearch(exeName, _pathEnv) then
		printError(textColor(_toolName, Color.Cyan) .. " is required to build the project. Please install " .. textColor(_toolName, Color.Cyan) .. " and make sure it's in your PATH.")
	end
end

checkPrerequisite( "git" )
if isRunningOnWindows() then
	checkPrerequisite( "sed" )
end

--------------------------------------------------------
-- Project loading and generation
--------------------------------------------------------
printInfo(textColor("\xE2\x96\xB6", Color.Green) .. textColor(" Loading scripts and generating projects...", Color.Cyan))

g_projectIsAdded	= {}
g_fileIsLoaded		= {}
g_projectScriptIsLoaded = {}

-- Returns true if the variable is a table
function isTable(_var)
	return type(_var) == "table"
end


-- Builds a standard source file pattern table for a given path with optional include path
function projectSourceFilesWildcard(...)
	local files = {}
    for i = 1, select('#', ...) do
        local p = select(i, ...)
        if p then
			-- ensure trailing slash for glob pattern
			if string.sub(p, -1) ~= "/" then p = p .. "/" end
			files[#files+1] = p .. "**.c"
			files[#files+1] = p .. "**.cpp"
			files[#files+1] = p .. "**.cxx"
			files[#files+1] = p .. "**.cc"
			files[#files+1] = p .. "**.h"
			files[#files+1] = p .. "**.hpp"
			files[#files+1] = p .. "**.hxx"
			files[#files+1] = p .. "**.inl"
        end
    end
    return files
end

local _projectIsCPPCache = {}
local _projectIsCPPExtensions = {
	[".cpp"] = true,
	[".cxx"] = true,
	[".cc"]  = true,
	[".hpp"] = true,
	[".hxx"] = true,
}

-- Returns true if any of the project files have a C++ extension
function projectIsCPP(_projectFiles)
	local cacheKey = table.concat(_projectFiles, "\n")
	local cached = _projectIsCPPCache[cacheKey]
	if cached ~= nil then
		return cached
	end

	for _, entry in ipairs(_projectFiles) do
		local extension = string.lower(path.getextension(entry))
		if _projectIsCPPExtensions[extension] then
			local exists = false
			if string.find(entry, "*", 1, true) ~= nil then
				exists = next(os.matchfiles(entry)) ~= nil
			else
				exists = os.isfile(entry)
			end

			if exists then
				_projectIsCPPCache[cacheKey] = true
				return true
			end
		end
	end

	_projectIsCPPCache[cacheKey] = false
	return false
end

-- Returns the project description string if a description function exists
function projectGetDescription(_name)
	local descFn = _G["projectDescription_" .. _name]
	if descFn then
		return descFn()
	end
	return nil
end

-- Returns the first element if the name is a table, otherwise the name itself
function projectGetBaseName(_projectName)
	if isTable(_projectName) then
		return _projectName[1]
	end
	return _projectName
end

-- Sanitizes a name by replacing dashes and dots with underscores
-- If table, flatten first
local g_cleanupCache = {}
function projectNameCleanup(_projectName)
	if g_cleanupCache[_projectName] then
		return g_cleanupCache[_projectName]
	end
	if isTable(_projectName) then
		local result = string.gsub(table.concat(_projectName, "_"), "[%-.]", "_")
		g_cleanupCache[_projectName] = result
		return result
	end
	local result = string.gsub(_projectName, "[%-.]", "_")
	g_cleanupCache[_projectName] = result
	return result
end

local g_projectPathCache		= {}
local g_projectPathScriptCache	= {}
local _pathAbsoluteCache		= {}
local _pathIsDirCache			= {}
local _pathIsFileCache			= {}
local _dirChildrenCache			= {}
local _dirChildrenByNameCache	= {}
local _scriptSearchCache		= {}
local _scriptSearchSubdirs		= { "scripts/", "zidar/", "genie/", "build/" }

local function pathGetAbsoluteCached(_path, _force)
	local cached = _pathAbsoluteCache[_path]
	if cached ~= nil and not _force then
		return cached
	end
	cached = string.gsub(path.getabsolute(_path), "\\", "/")
	_pathAbsoluteCache[_path] = cached
	return cached
end

local function pathIsDirCached(_path, _force)
	local cached = _pathIsDirCache[_path]
	if cached ~= nil and not _force then
		return cached
	end
	cached = os.isdir(_path)
	_pathIsDirCache[_path] = cached
	return cached
end

local function pathIsFileCached(_path, _force)
	local cached = _pathIsFileCache[_path]
	if cached ~= nil and not _force then
		return cached
	end
	cached = os.isfile(_path)
	_pathIsFileCache[_path] = cached
	return cached
end

local function getChildDirsCached(_dir)
	local absDir = pathGetAbsoluteCached(_dir)
	local cached = _dirChildrenCache[absDir]
	if cached ~= nil then
		return _dirChildrenByNameCache[absDir], cached
	end

	local byName = {}
	local dirs = {}
	local seen = {}
	for _,sub in ipairs(os.matchdirs(absDir .. "/*")) do
			local absSub = pathGetAbsoluteCached(sub)
			if not seen[absSub] then
				seen[absSub] = true
				dirs[#dirs + 1] = absSub
				local baseName = path.getbasename(absSub)
				if byName[baseName] == nil then
					byName[baseName] = absSub
				end
			end
		end

	_dirChildrenByNameCache[absDir] = byName
	_dirChildrenCache[absDir] = dirs
	return byName, dirs
end

local _dirByNameSearchCache = {}
local function findDirByNameRecursive(_dir, _name, _depth, _maxDepth, _validator)
	local absDir = pathGetAbsoluteCached(_dir)
	local cacheKey = absDir .. "|" .. _name
	local cached = _dirByNameSearchCache[cacheKey]
	if cached ~= nil then
		return cached ~= false and cached or nil
	end

	if string.find(absDir, "/zidar/3rd", 1, true) then
		_dirByNameSearchCache[cacheKey] = false
		return nil
	end

	local childDirsByName, childDirs = getChildDirsCached(absDir)
	if childDirsByName[_name] ~= nil then
		local candidate = childDirsByName[_name]
		if not _validator or _validator(candidate) then
			_dirByNameSearchCache[cacheKey] = candidate
			return candidate
		end
	end

	if _depth < _maxDepth then
		for _, subDir in ipairs(childDirs) do
			local found = findDirByNameRecursive(subDir, _name, _depth + 1, _maxDepth, _validator)
			if found then
				_dirByNameSearchCache[cacheKey] = found
				return found
			end
		end
	end

	_dirByNameSearchCache[cacheKey] = false
	return nil
end

local function findScriptInProjectDir(_projectDir, _scriptName)
	if _projectDir == nil then
		return nil
	end

	local absProjectDir = pathGetAbsoluteCached(_projectDir)
	for _, subdir in ipairs(_scriptSearchSubdirs) do
		local candidate = path.join(absProjectDir, subdir .. _scriptName)
		if pathIsFileCached(candidate) then
			return pathGetAbsoluteCached(candidate)
		end
	end

	return nil
end

local function findScriptInDirCached(_dir, _depth, _maxDepth, _scriptName)
	local absDir = pathGetAbsoluteCached(_dir)
	local cacheKey = absDir .. "|" .. _scriptName
	local cached = _scriptSearchCache[cacheKey]
	if cached ~= nil then
		return cached ~= false and cached or nil
	end

	if string.find(absDir, "/zidar/3rd", 1, true) then -- exclude 3rd party 
		_scriptSearchCache[cacheKey] = false
		return nil
	end

	for _, subdir in ipairs(_scriptSearchSubdirs) do
		local candidate = path.join(absDir, subdir .. _scriptName)
		if pathIsFileCached(candidate) then
			local result = pathGetAbsoluteCached(candidate)
			_scriptSearchCache[cacheKey] = result
			return result
		end
	end

	if _depth < _maxDepth then
		local _, childDirs = getChildDirsCached(absDir)
		for _, childDir in ipairs(childDirs) do
			local result = findScriptInDirCached(childDir, _depth + 1, _maxDepth, _scriptName)
			if result then
				_scriptSearchCache[cacheKey] = result
				return result
			end
		end
	end

	_scriptSearchCache[cacheKey] = false
	return nil
end

-- Returns true if a specially named header exists in the given path, indicating that the project requires bgfx
function projectRequiresBGFX(_sourcePath)
	if pathIsFileCached(_sourcePath .. "/" .. projectNameCleanup(project().name) .. "_uses_bgfx.h") then
		return true
	end
	return false
end

-- Returns the install destination path for a 3rd party dependency
function projectInstallDestination(_name)
	local name = projectGetBaseName(_name)
	return RG_DEPENDENCY_DIR .. "/" .. projectNameCleanup(name)
end

-- Downloads and installs a 3rd party library via git clone
function projectInstall3rdPartyLib(_name)
	local name = projectGetBaseName(_name)
	local destination = projectInstallDestination(_name)
	local downloadLink = nil

	local buildName = projectNameCleanup(name)
	if _G["projectSource_" .. buildName] ~= nil then -- prebuilt libs have no projects
		downloadLink = _G["projectSource_" .. buildName]()
	end
	-- not found? try to download it
	if downloadLink then
		print("Downloading " .. textColor(name, Color.Cyan) .. " from: " .. textColor(downloadLink, Color.Yellow))
		if not pathIsDirCached(destination) then
			if not os.execute("git clone " .. downloadLink .. " " .. destination) then
				printError("Failed to download missing dependency: " .. textColor(name, Color.Red))
			end
			return pathIsDirCached(destination, true)
		end
	else
		printError("No link to download source code of missing dependency found: " .. name)
	end	
	return false
end

-- Returns true if the path is a filesystem root (parent equals itself)
function pathIsRootPath(_path)
	if RG_ZIDAR_HOME_DIR and RG_ZIDAR_HOME_DIR == _path then
		return true
	end
	return _path == "/" or _path:match("^%a:/$")
end

-- Caches a project's resolved directory path, errors on conflict
function projectAddPathToCache(_name, _path)
	local name = projectGetBaseName(_name)
	if g_projectPathCache[name] then
		if g_projectPathCache[name] ~= _path then
			printError("Project path cache conflict for project " .. name .. " - already have path: " .. g_projectPathCache[name] .. ", new path: " .. _path)
		end
		return
	end
	g_projectPathCache[name] = _path
end

-- Searches parent directories for a project folder, returns its absolute path or nil
function projectGetPath(_name, _canFail)
	local name = projectGetBaseName(_name)

	if g_projectPathCache[name] ~= nil then
		return g_projectPathCache[name]
	end

	local function isValidProjectDir(dir)
		return pathIsFileCached(path.join(dir, "scripts/genie.lua"))
			or pathIsFileCached(path.join(dir, "genie/genie.lua"))
	end

	local searchDir	= pathGetAbsoluteCached(_WORKING_DIR)
	local result	= nil

	-- deep search walking up parent directories
	while not result do
		if path.getbasename(searchDir) == name and isValidProjectDir(searchDir) then
			result = searchDir
			break
		end

		local found = findDirByNameRecursive(searchDir, name, 0, 3, isValidProjectDir)
		if found then
			result = found
			break
		end

		if pathIsRootPath(searchDir) then
			break
		end

		local parent = pathGetAbsoluteCached(path.join(searchDir, ".."))
		if parent == searchDir or (RG_ZIDAR_HOME_DIR and searchDir == pathGetAbsoluteCached(RG_ZIDAR_HOME_DIR)) then
			break
		end
		searchDir = parent
	end

	-- check 3rd party libraries
	if not result and RG_3RD_PARTY_SCRIPTS[name] then
		result = projectInstallDestination(_name)
	end

	if result then
		projectAddPathToCache(_name, result)
	end

	if not result and not _canFail then
		printWarning("Project " .. textColor(name, Color.Cyan) .. " not found but path requested.")
	end

	return result
end

RG_CORE_COMPAT_DIR = path.join(projectGetPath("rg_core", true), "include/compat")

-- Locates the build script (.lua) for a project by searching known directories
function projectGetScriptPath(_name, _requester)
	
	local name = projectGetBaseName(_name)

	if g_projectPathScriptCache[name] ~= nil then
		return g_projectPathScriptCache[name]
	end

	if RG_3RD_PARTY_SCRIPTS[name] then
		g_projectPathScriptCache[name] = RG_3RD_PARTY_SCRIPTS[name]
		return RG_3RD_PARTY_SCRIPTS[name]
	end

	local scriptName = name .. ".lua"
	local projectDir = projectGetPath(_name)
	local result = findScriptInProjectDir(projectDir, scriptName)
	if result then
		g_projectPathScriptCache[name] = result
		return result
	end

	-- check _WORKING_DIR first (fast)
	local depthToSearch = 3 -- search up to 3 levels deep in subdirectories
	result = findScriptInDirCached(_WORKING_DIR, 0, depthToSearch, scriptName)

	if result then
		g_projectPathScriptCache[name] = result
		return result
	end

	-- search upward through parent directories looking for
	-- a directory with matching name
	local searchDir = pathGetAbsoluteCached(_WORKING_DIR)
	while not pathIsRootPath(searchDir) do
		local upDir = pathGetAbsoluteCached(path.join(searchDir, ".."))
		if upDir == searchDir then break end

		local upResult = findScriptInDirCached(upDir, 0, depthToSearch, scriptName)
		if upResult then
			result = upResult
			break
		end
		searchDir = upDir
	end

	if not result then
		printError("Could not find or download dependency - " .. textColor(name, Color.Cyan))
	end

	if result then
		g_projectPathScriptCache[name] = result
	end

	return result
end

-- Returns a table with .script and .path for the given project name
function projectGetPaths(_name)
	return projectGetScriptPath(_name), projectGetPath(_name)
end

-- Returns the public header directory for a project ("include" or "inc"), or nil if neither exists
function projectGetIncludePath(_projectPath)
	local inclPath = _projectPath .. "/include"
	if pathIsDirCached(inclPath) then return inclPath end
	local incPath = _projectPath .. "/inc"
	if pathIsDirCached(incPath) then return incPath end
	return nil
end

-- Adds a directory to the include path if it exists
function addIncludePath(_name, _path)
	assert(_path ~= nil)
	if string.len(_path) == 0 then return end

	if pathIsDirCached(_path) then 
		includedirs { _path } 
	end
end

-- Adds standard include paths (parent, include/, inc/) for a dependency
function addIncludePaths(_name, _projectName)
	local basename = projectGetBaseName(_projectName)

	local projectDir = projectGetPath(_projectName)
	if projectDir == nil then return end

	local projectParentDir = pathGetAbsoluteCached(path.join(projectDir, "../"))
	if projectParentDir == nil then return false end

	-- search for it..
	addIncludePath(_name, projectParentDir)
	addIncludePath(_name, projectDir .. "/include")
	addIncludePath(_name, projectDir .. "/inc")
	addIncludePath(_name, projectDir .. "/src") -- some projects put headers in src
end

-- Recursively adds a project and its dependencies to the solution
function projectAdd(_name)
	local name = projectNameCleanup(_name)
	if g_projectIsAdded[name] == nil then
		local projectPath = projectGetPath(name)
		if not projectPath then
			local oslib = os.findlib(_name)
			if not oslib then
				printError("Could not find project or OS library for dependency - " .. _name)
				return
			end
			printWarning("Project " .. textColor(name, Color.Cyan) .. " not found, but found OS library: " .. textColor(oslib, Color.Yellow) .. ". Linking against it instead.")
			links { oslib }
			return
		end
		local dependencies = projectGetDependencies(name)
		for _,dependency in ipairs(dependencies) do
			projectAdd(dependency)
		end

		if _G["projectAdd_" .. name] ~= nil then -- prebuilt libs have no projects
			_G["projectAdd_" .. name]()
			g_projectIsAdded[name] = true
		else
			printWarning("Project " .. textColor(name, Color.Cyan) .. " being added, but no add function found. Forgotten to load the project script?")
		end
	end
end

--
function configDependency(dependency)
	local dependencyClean = projectNameCleanup(dependency)
	if _G["projectDependencyConfig_" .. dependencyClean] ~= nil then -- prebuilt libs have no projects
		return _G["projectDependencyConfig_" .. dependencyClean]()
	end
end

--
function printProjectAdded(_name, _path)
	print("\xE2\x80\xA2 " .. textColor(textFixedWidth(_name), Color.Cyan) .. " \xE2\x86\x92 " .. textColor(_path, Color.Blue))
end

--
function projectLoad(_projectName, _loadAndAdd)
	local scriptPath, 
	      projectPath	= projectGetPaths(_projectName) -- this will load the project script and cache the path, if not already cached
	local name			= projectGetBaseName(_projectName)

	g_projectScriptIsLoaded[name] = true

	if scriptPath ~= nil then
		if pathIsFileCached(scriptPath) then
			if g_fileIsLoaded[scriptPath] == nil then
				assert(loadfile(scriptPath))(projectPath)

				if not pathIsDirCached(projectPath) then
					if not projectInstall3rdPartyLib(_projectName) then
						printError("Could not find or download dependency - " .. _projectName)
					end					
				end

				if _G["projectAdd_" .. name] == nil then -- prebuilt libs have no projects
					printWarning("Project " .. textColor(name, Color.Cyan) .. " loaded, but no add function found. This may be a prebuilt library, if so this message can be ignored.")
				end

				-- default to true/add
				if _loadAndAdd == nil or _loadAndAdd then
					projectAdd(_projectName)
				end

				g_fileIsLoaded[scriptPath] = true
			end
		end
	else
		printWarning("Could not find script for project - " .. _projectName)
	end
end

local function projectLoadIfNeeded(_projectName, _loadAndAdd)
	local name = projectGetBaseName(_projectName)
	if g_projectScriptIsLoaded[name] then
		return  
	end
	projectLoad(_projectName, _loadAndAdd)
end

local g_subDependenciesCount = {}
local g_resolvedDependencies = {}

--
function sortDependencies(a,b)
	local countA = g_subDependenciesCount[a] or 0
	local countB = g_subDependenciesCount[b] or 0
	return countA > countB
end

--
function projectGetDependencies(_name, _additionalDeps)
	local fullName = projectNameCleanup(_name)
   
	-- use cached result when no additional deps are supplied
	local hasAdditionalDeps = _additionalDeps ~= nil and #_additionalDeps > 0
	if not hasAdditionalDeps and g_resolvedDependencies[_name] then
		g_subDependenciesCount[_name] = #g_resolvedDependencies[_name]
		return g_resolvedDependencies[_name]
	end

	local dependenciesHashed = {}
	local dependencies		 = {}
	local scriptDeps		 = {}

	if _G["projectDependencies_" .. fullName] then
		scriptDeps = _G["projectDependencies_" .. fullName]()
		for _,dep in ipairs(scriptDeps) do
			if not dependenciesHashed[dep] then
				dependencies[#dependencies + 1] = dep
				dependenciesHashed[dep] = true
			end
		end
	end

	_additionalDeps	= _additionalDeps or {}
	for _,dep in ipairs(_additionalDeps) do
		if not dependenciesHashed[dep] then
			dependencies[#dependencies + 1] = dep
			dependenciesHashed[dep] = true
		end
	end

	for _,dep in ipairs(_additionalDeps) do
	    projectLoadIfNeeded(dep, false)
	end

	for _,dependency in ipairs(scriptDeps) do
		projectLoadIfNeeded(dependency, false) -- do not add
	end

	for _,d in ipairs(dependencies) do
		local depNested = projectGetDependencies(d)
		for _,dep in ipairs(depNested) do
			if not dependenciesHashed[dep] then
				dependencies[#dependencies + 1] = dep
				dependenciesHashed[dep] = true
			end
		end
	end

	if _ACTION == "gmake" then
		for _,dep in ipairs(dependencies) do
			if not g_subDependenciesCount[dep] then
				projectGetDependencies(dep)
			end
		end
		table.sort(dependencies, sortDependencies)
	end

	for _,dependency in ipairs(dependencies) do
		configDependency(dependency)
	end

	if not hasAdditionalDeps then
		g_resolvedDependencies[_name] = dependencies
	end

	g_subDependenciesCount[_name]		= #dependencies
	return dependencies
end

--
function addExtraSettingsForExecutable(_name)
	local fullProjectName = projectNameCleanup(_name)
	if _G["projectExtraConfigExecutable_" .. fullProjectName] then
		_G["projectExtraConfigExecutable_" .. fullProjectName]()
	end
end

-- can be called only ONCE from one project, merge dependencies before calling!!!
function addDependencies(_name, _additionalDeps)
	local dependencies = projectGetDependencies(_name, _additionalDeps)
	addExtraSettingsForExecutable(_name)
	printProjectAdded(_name, projectGetPath(_name))

	if dependencies ~= nil then
		for _,dependency in ipairs(dependencies) do
			if dependency ~= nil then
				local depName = projectNameCleanup(dependency)

				addExtraSettingsForExecutable(depName)
				addIncludePaths(_name, dependency)

				if _G["projectHeaderOnlyLib_" .. depName] == nil then
					links { depName }
				end

				if g_projectIsAdded[depName] == nil then
					projectAdd(depName)
				end
			end
		end
	end
end

--
function addLibSubProjects_samples(_name)

	local name = projectNameCleanup(_name)
	if isTable(_name) then return end

	g_projectIsAdded[name] = true
	local projectDir = projectGetPath(_name)
	if projectDir == nil then return end
	local samplesDir = projectDir .. "/samples/"
	local sampleDirs = os.matchdirs(samplesDir .. "*") 
	for _,dir in ipairs(sampleDirs) do
		local dirName = path.getbasename(dir)
		projectAddPathToCache(_name .. "_" .. dirName, dir)
		addProject_lib_sample(_name, dirName)
	end
end

--
function addLibSubProjects_unittests(_name)

	local name = projectNameCleanup(_name)
	if isTable(_name) then return end

	g_projectIsAdded[name] = true
	local projectDir = projectGetPath(_name)
	if projectDir == nil then return end

	local testDir = projectDir .. "/tests/"
	if pathIsDirCached(testDir) then
		projectAddPathToCache(_name .. "_test", testDir)
		addProject_lib_test(_name)
	end
end

--
function addLibSubProjects_tools(_name)

	local name = projectNameCleanup(_name)
	if isTable(_name) then return end

	g_projectIsAdded[name] = true
	local projectDir = projectGetPath(_name)
	if projectDir == nil then return end

	local toolsDirs = os.matchdirs(projectDir .. "/tools/*") 
	for _,dir in ipairs(toolsDirs) do
		local dirName = path.getbasename(dir)
		projectAddPathToCache(_name .. "_" .. dirName, dir)
		addProject_lib_tool(_name, dirName)
	end
end

--
function addLibProjects(_name)

	projectLoad(_name)
	local shouldAddLibProjects = _name == solution().name

	-- same as above
	if (_OPTIONS["with-unittests"] ~= nil) and shouldAddLibProjects then
		addLibSubProjects_unittests(_name)
	end

	-- we're adding library samples only if it's a main solution
	-- in other words, only in library development mode.
	if (_OPTIONS["with-samples"] ~= nil) and shouldAddLibProjects then
		addLibSubProjects_samples(_name)
	end


	-- adding library tools always, if requested
	if (_OPTIONS["with-tools"] ~= nil) then
		addLibSubProjects_tools(_name)
	end
end

--
function getToolForHost(_name)

	local projectDir = projectGetPath("zidar")

	if not projectDir then
		printError("zidar project directory not found, cannot determine tool paths")
	end

	local toolPath = path.getabsolute(projectDir .. "/tools/bin/")

	if os.is("windows") then
		toolPath = toolPath .. "/windows/" .. _name .. ".exe"
	elseif os.is("linux") then
		toolPath = toolPath .. "/linux/" .. _name
	elseif os.is("osx") then
		toolPath = toolPath .. "/darwin/" .. _name
	end

	return toolPath
end

--
function projectGetTemporaryIncludePath(_project)
	local solutionDir = getSolutionBaseDir()
	os.mkdir(solutionDir .. "/include/" .. _project)
	return solutionDir .. "/include/" .. _project
end

-- read file contents
function fileRead(_file)
    local f = io.open(_file, "r")
	if f == nil then return "" end
    local content = f:read("*all")
    f:close()
    return content
end
