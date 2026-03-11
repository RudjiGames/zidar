--
-- Copyright 2025 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--

local params = { ... }
local RTM_ADD_SEARCH_PATH = params[1] or nil

--------------------------------------------------------
-- directories
--------------------------------------------------------

function script_dir()
	return path.getdirectory(debug.getinfo(2, "S").source:sub(2)) .. "/"
end

RTM_SCRIPTS_DIR			= script_dir()
RTM_ROOT_DIR			= path.getabsolute(RTM_SCRIPTS_DIR .. "../") .. "/"		-- project root
RTM_BUILD_DIR			= RTM_ROOT_DIR .. ".build/"								-- temp build files
RTM_LOCATION_PATH		= ""													-- solution/makefile/etc.

RTM_PROJECT_DIRS  = {}

newoption {
	trigger = "project-dirs",
	description = "Specify file with project search paths table (has to be named RTM_PROJECT_DIR_PATHS)"
}

newoption {
	trigger = "with-samples",
	description = "Generates library sample projects"
}

newoption {
	trigger = "with-unittests",
	description = "Generates library unit test projects"
}

newoption {
	trigger = "with-tools",
	description = "Generates library tools projects"
}

local customProjectDirs = _OPTIONS["project-dirs"]
if (customProjectDirs == nil) then
    customProjectDirs = script_dir() .. "rtm_paths.lua"
end

customProjectDirs = path.getabsolute(customProjectDirs)
if (not os.isfile(customProjectDirs)) then                  
    customProjectDirs = _WORKING_DIR .. '/' .. customProjectDirs
end

if (os.isfile(customProjectDirs)) then
    dofile (customProjectDirs)
    for _,pathTable in ipairs(RTM_PROJECT_DIR_PATHS) do
		local relative	= pathTable[1]
		local path		= pathTable[2]
		if relative then
			path = RTM_ROOT_DIR .. path
		end
        if os.isdir(path) then
            table.insert(RTM_PROJECT_DIRS, path) 
        end
    end
else
    print("ERROR: Custom project directories script not found at " .. customProjectDirs)
    os.exit()
    return
end

-- add extra search path, passed on from the invoking script
if RTM_ADD_SEARCH_PATH ~= nil then
	RTM_ADD_SEARCH_PATH = path.getabsolute(RTM_ADD_SEARCH_PATH.. "../../../") .. "/"
	if os.isdir(RTM_ADD_SEARCH_PATH) then
		table.insert(RTM_PROJECT_DIRS, RTM_ADD_SEARCH_PATH) 
	else
		print("Warning: path does not exist: " .. RTM_ADD_SEARCH_PATH)	
	end
end

dofile (RTM_SCRIPTS_DIR .. "toolchain.lua")

if _ACTION == "clean" then
	rmdir(RTM_BUILD_DIR)
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
ExtraDefines["debug"]   = { "RTM_DEBUG_BUILD", "_DEBUG", "DEBUG" }
ExtraDefines["release"] = { "RTM_RELEASE_BUILD", "NDEBUG" }
ExtraDefines["retail"]	= { "RTM_RETAIL_BUILD", "NDEBUG", "RETAIL" }

--------------------------------------------------------
-- utility functions to check for target compiler
--------------------------------------------------------

function actionUsesGCC()
	return ("gmake" == _ACTION or "codelite" == _ACTION or "codeblocks" == _ACTION or "xcode3" == _ACTION)
end

function actionUsesMSVC()
	return (_ACTION ~= nil and _ACTION:find("vs"))
end

function actionUsesXcode()
	return (_ACTION ~= nil and _ACTION:find("xcode"))
end

--------------------------------------------------------
-- fixup for precompiled header path
--------------------------------------------------------

function getPCHPath(_path, _projectName, _projType)
	local fullPath = _path .. _projectName .. "_pch.h"
	if os.isfile(fullPath) == false then
		return nil
	end
	local retPath = _projectName .. "_pch.h"
	if actionUsesGCC() then
		retPath = _path .. retPath
	end
	return retPath
end

function addPCH(_path, _name)
	local PCH = getPCHPath(_path, _name)
	if PCH ~= nil and not os.is("macosx") then
		pchheader (PCH)
		if path.isFile(_path .. _name .. "_pch.cpp") then
			pchsource (_path .. _name .. "_pch.cpp")
		end
		if path.isFile(_path .. _name .. "_pch.c") then -- support C projects as well
			pchsource (_path .. _name .. "_pch.c")
		end
	end
end

--------------------------------------------------------
-- Library types
--------------------------------------------------------

Lib = {
	Runtime	= {},
	Tool	= {},
	Game	= {}
}

dofile (RTM_SCRIPTS_DIR .. "project_3rd.lua")
dofile (RTM_SCRIPTS_DIR .. "project_cmdtool.lua")
dofile (RTM_SCRIPTS_DIR .. "project_game.lua")
dofile (RTM_SCRIPTS_DIR .. "project_lib.lua")
dofile (RTM_SCRIPTS_DIR .. "project_lib_sample.lua")
dofile (RTM_SCRIPTS_DIR .. "project_lib_test.lua")
dofile (RTM_SCRIPTS_DIR .. "project_lib_tool.lua")
dofile (RTM_SCRIPTS_DIR .. "project_qt.lua")

--------------------------------------------------------
-- helper functions
--------------------------------------------------------
function mergeTwoTables(_table1, _table2)
	_table1 = _table1 or {}
	_table2 = _table2 or {}
	local mergedTable = {}
	local hash = {}
	for _,v1 in ipairs(_table1) do 
		if (not hash[v1]) then
			table.insert(mergedTable, v1)
			hash[v1] = true
		end
	end
	for _,v2 in ipairs(_table2) do 
		if (not hash[v2]) then
			table.insert(mergedTable, v2)
			hash[v2] = true
		end
	end
	return mergedTable
end

function mergeTables(_table1, _table2, _table3, _table4, _table5, _table6, _table7, _table8)
	_table1 = _table1 or {}		_table2 = _table2 or {}
	_table3 = _table3 or {}		_table4 = _table4 or {}
	_table5 = _table5 or {}		_table6 = _table6 or {}
	_table7 = _table7 or {}		_table8 = _table8 or {}
	local t1 = mergeTwoTables(_table1, _table2)
	local t2 = mergeTwoTables(_table3, _table4)
	local t3 = mergeTwoTables(_table5, _table6)
	local t4 = mergeTwoTables(_table7, _table8)
	return mergeTwoTables(mergeTwoTables(t1, t2), mergeTwoTables(t3, t4))
end

ProjectLoad = {
	LoadOnly	= {},
	LoadAndAdd	= {}
}

g_projectIsLoaded	= {}
g_projectIsAdded	= {}
g_projectLoadCalled	= {}
g_fileIsLoaded		= {}

function getProjectDesc(_name)
	local descFn = _G["projectDescription_" .. _name]
	if descFn then
		return descFn()
	end
	return nil
end

ProjectPath = {
	Dir		= {},
	Root	= {}
}

function istable(_var)
	return type(_var) == "table"
end

function getProjectBaseName(_projectName)
	if istable(_projectName) then
		for _,name in ipairs(_projectName) do
			return name
		end
	end
	return _projectName
end

function buildifyName(_name)
	local nameWithUnderscore = string.gsub(_name, "-", "_")
	local nameNoDot = string.gsub(nameWithUnderscore, "%.", "_")
	return nameNoDot
end

function getProjectFullName(_projectName)
	if istable(_projectName) then
		local ret = nil
		for _,name in ipairs(_projectName) do
			if ret == nil then ret = name else ret = ret .. "_" .. name end
		end
		return buildifyName(ret)
	else
		return buildifyName(_projectName)
	end
end

g_3rdPartyProjectPathCache = {}

function find3rdPartyProject(_name)

	if g_3rdPartyProjectPathCache[_name] ~= nil then
		return g_3rdPartyProjectPathCache[_name]
	end

	if istable(_name) then return nil end
	
	local name = getProjectBaseName(_name)
	
	for _,dir in ipairs(RTM_PROJECT_DIRS) do
		local libDir = dir .. name
		if os.isdir(libDir) then
			local projectPath = libDir .. "/"
			g_3rdPartyProjectPathCache[_name] = projectPath
			return projectPath
		end
		local subDirs = os.matchdirs(dir .. "*")
		for _,subDir in ipairs(subDirs) do
			local subPath = subDir .. "/3rd/" .. name
			if os.isdir(subPath) then
				g_3rdPartyProjectPathCache[_name] = subPath .. "/"
				return subPath .. "/"
			end
		end
	end

	return nil	
end

g_projectPathCache = {}

function getProjectPath(_name, _pathType)
	local name = getProjectBaseName(_name)
	local full_name = getProjectFullName(_name)
	_pathType = _pathType or ProjectPath.Dir

	local key
	if _pathType == ProjectPath.Dir then
		key = name .. "_dir"
	else
		key = name .. "_root"
	end

	if g_projectPathCache[key] ~= nil then
		return g_projectPathCache[key]
	end

	local projectPath
	for _,dir in ipairs(RTM_PROJECT_DIRS) do
		local libDir = dir .. name
		if os.isdir(libDir) then 
			if _pathType == ProjectPath.Dir then
				g_projectPathCache[key] = path.getabsolute(libDir .. "/");
				return path.getabsolute(libDir .. "/")
			else
				g_projectPathCache[key] = path.getabsolute(dir)
				return path.getabsolute(dir)
			end
		end
	end

	projectPath = find3rdPartyProject(_name)
	if projectPath ~= nil then
		if _pathType == ProjectPath.Root then
			g_projectPathCache[key] = path.getabsolute(projectPath .. "../") .. "/"
			return path.getabsolute(projectPath .. "../") .. "/"
		else
			g_projectPathCache[key] = path.getabsolute(projectPath)
			return path.getabsolute(projectPath)
		end
	end

 	for _,dir in ipairs(RTM_PROJECT_DIRS) do
		local subDirs = os.matchdirs(dir .. "*")
		for _,subDir in ipairs(subDirs) do
			local pth = path.getabsolute(subDir .. "/tools/" .. name)
			if file_isdir(pth) then
				g_projectPathCache[key] = pth
				return pth
			end

			pth = path.getabsolute(subDir .. "/3rd/" .. name .. "/")
			if file_isdir(pth) then
				g_projectPathCache[key] = pth
				return pth
			end
		end
	end

	return nil
end

function addIncludePath(_name, _path)
	assert(_path ~= nil)
	if string.len(_path) == 0 then return end
	if os.isdir(_path) then includedirs { _path } end
end

function addInclude(_name, _projectName)
	local basename = getProjectBaseName(_projectName)
	local fullname = getProjectFullName(_projectName)

	local projectParentDir = getProjectPath(_projectName, ProjectPath.Root)
	if projectParentDir == nil then return false end

	-- search for it..
	addIncludePath(_name, projectParentDir)
	addIncludePath(_name, projectParentDir .. "/" .. basename .. "/include")
	addIncludePath(_name, projectParentDir .. "/" .. basename .. "/inc")
	addIncludePath(_name, projectParentDir .. "/" .. basename)
end

g_projectAddCache = {}

function addProject(_name)
	local name = getProjectFullName(_name)

	if g_projectAddCache[_name] ~= nil then
		return 
	end

	g_projectAddCache[_name] = true

	local deps = getProjectDependencies(_name)
	for _,dep in ipairs(deps) do
		addProject(dep)
	end

	if g_projectIsLoaded[name] == nil then
		local nameBuild = buildifyName(name)
		if _G["projectAdd_" .. nameBuild] ~= nil then -- prebuilt libs have no projects
			_G["projectAdd_" .. nameBuild]()
			g_projectIsLoaded[name] = true
		end
	end

	if g_projectIsLoaded[name] == nil then
		if find3rdPartyProject(name) == nil then
			-- some 'missing' dependencies are actually system libraries, for example X11, GL, etc.
			-- if we cannot find it on OS level - warn user
			if os.findlib(name) == nil then
				print('WARNING: Dependency not found - ' .. name .. ' - treating it as a system library')
			end
		end
	end

	if (_OPTIONS["with-tools"] ~= nil) then
		local projectDir = getProjectPath(_name, ProjectPath.Dir)
		if projectDir ~= nil then
			local toolDirs = os.matchdirs(projectDir .. "/tools/*")
			for _,toolPath in ipairs(toolDirs) do
				local tool = path.getbasename(toolPath)
				local scriptPath = toolPath .. "/genie/" .. tool .. ".lua"
				if file_exists(scriptPath) then
					dofile(scriptPath)
					if _G["projectAdd_" .. tool] ~= nil then
						_G["projectAdd_" .. tool](toolPath)
						g_projectIsLoaded[tool] = true
					end
				end
			end
		end
	end
end

function configDependency(dependency)
	local dependency = getProjectFullName(dependency)
	if _G["projectDependencyConfig_" .. dependency] ~= nil then -- prebuilt libs have no projects
		return _G["projectDependencyConfig_" .. dependency]()
	end
end

function loadProject(_projectName, _load)

	local name = getProjectBaseName(_projectName)
	if name ~= nil then
		local prjFile = ""
		for _,path in ipairs(RTM_PROJECT_DIRS) do
				prjFile = path .. name .. ".lua"
				if os.isfile(prjFile) then
					if g_fileIsLoaded[prjFile] == nil then
						g_fileIsLoaded[prjFile] = true

						local projectName = find3rdPartyProject(name);
						if projectName ~= nil then
							assert(loadfile(prjFile))(projectName)
						end
						break
					end
				end
				prjFile = path .. name .. "/genie/" .. name .. ".lua"
				if os.isfile(prjFile) then
					if g_fileIsLoaded[prjFile] == nil then
						g_fileIsLoaded[prjFile] = true
						dofile(prjFile)
						break
					end
				end
		end
	end

	_load = _load or ProjectLoad.LoadAndAdd
	if _load == ProjectLoad.LoadAndAdd then
		addProject(_projectName)
	end
end

function sortDependencies(a,b)
	local depsA = getProjectDependencies(a)
	local depsB = getProjectDependencies(b)
	return #depsA > #depsB
end

function getProjectDependencies(_name, _additionalDeps)
	local fullName = getProjectFullName(_name)
   
	local dep = {}
	if _G["projectDependencies_" .. fullName] then
		dep = _G["projectDependencies_" .. fullName]()
	end

	local finalDep = {}

	_additionalDeps = _additionalDeps or {}
	dep = mergeTables(dep, _additionalDeps)

	for _,dependency in ipairs(dep) do
		table.insert(finalDep, dependency)
	end

	for _,dependency in ipairs(finalDep) do
		loadProject(dependency, ProjectLoad.LoadOnly)
	end

	local depNest = {}
	for _,d in ipairs(finalDep) do
		depNest = mergeTables(depNest, getProjectDependencies(d))
	end

	finalDep = mergeTables(finalDep, depNest)

	if _ACTION == "gmake" then
		table.sort(finalDep, sortDependencies)
	end

	for _,dependency in ipairs(finalDep) do
		local full = getProjectFullName(dependency)
		if _G["projectDependencyConfig_" .. full] then
			dep = _G["projectDependencyConfig_" .. full]()
		end
	end

	return finalDep
end

function addExtraSettingsForExecutable(_name)
	local fullProjectName = getProjectFullName(_name)
	if _G["projectExtraConfigExecutable_" .. fullProjectName] then
		dep = _G["projectExtraConfigExecutable_" .. fullProjectName]()
	end
end

-- can be called only ONCE from one project, merge dependencies before calling!!!
function addDependencies(_name, _additionalDeps)
	local dependencies = getProjectDependencies(_name, _additionalDeps)

	addExtraSettingsForExecutable(_name)

	if dependencies ~= nil then
		for _,dependency in ipairs(dependencies) do
			if dependency ~= nil then
				local dependencyFullName = getProjectFullName(dependency)

				addExtraSettingsForExecutable(dependencyFullName)
				addInclude(_name, dependency)

				if _G["projectHeaderOnlyLib_" .. dependencyFullName] == nil then
					links { dependencyFullName }
				end
			end
		end
	end
	
	if dependencies ~= nil then
		for _,dependency in ipairs(dependencies) do
			loadProject(dependency)
		end
	end
end

function addLibSubProjects_samples(_name)

	if istable(_name) then return end

	g_projectIsLoaded[_name] = true

	local projectDir = getProjectPath(_name)
	if projectDir == nil then return end

	-- Add unit sample projects only if rapp dependency can be found
	local rapp = getProjectPath("rapp")
	if rapp ~= nil then
		local sampleDirs = os.matchdirs(projectDir .. "/samples/*") 
		for _,dir in ipairs(sampleDirs) do
			local dirName = path.getbasename(dir)
			addProject_lib_sample(_name, dirName)
		end
	end
end

function addLibSubProjects_unittests(_name)

	if istable(_name) then return end

	g_projectIsLoaded[_name] = true

	local projectDir = getProjectPath(_name)
	if projectDir == nil then return end

	-- Add unit test projects only if unittest-cpp dependency can be found
	local unittest_path = find3rdPartyProject("unittest-cpp")
	if unittest_path ~= nil then
		local testDir = projectDir .. "/test/"
		if os.isdir(testDir) then
			addProject_lib_test(_name)
 		end
	end
end

function addLibSubProjects_tools(_name)

	if istable(_name) then return end

	g_projectIsLoaded[_name] = true

	local projectDir = getProjectPath(_name)
	if projectDir == nil then return end

	local toolsDirs = os.matchdirs(projectDir .. "/tools/*") 
	for _,dir in ipairs(toolsDirs) do
		local dirName = path.getbasename(dir)
		addProject_lib_tool(_name, dirName)
	end
end

function addLibProjects(_name)
	loadProject(_name)

	local addLibProjects = _name == solution().name

	-- we're adding library samples only if it's a main solution
	-- in other words, only in library development mode.
	if (_OPTIONS["with-samples"] ~= nil) and addLibProjects then
		addLibSubProjects_samples(_name)
	end

	-- same as above
	if (_OPTIONS["with-unittests"] ~= nil) and addLibProjects then
		addLibSubProjects_unittests(_name)
	end

	-- adding library tools always, if requested
	if (_OPTIONS["with-tools"] ~= nil) then
		addLibSubProjects_tools(_name)
	end
end

function stripExtension( _path )
	local pathFS = _path:gsub("\\","/")
	return path.getdirectory(pathFS) .. "/" .. path.getbasename(pathFS)
end

function getToolForHost(_name)
	-- sed is special case
	if _name == "sed" and os.is("windows") then
		return getProjectPath("build") .. "\\tools\\bin\\windows\\sed.exe"
	end

	local toolPath = path.getabsolute(script_dir() .. "/tools/bin/")
	if os.is("windows") then
		toolPath = toolPath .. "/windows/" .. _name .. ".exe"
	elseif os.is("linux") then
		toolPath = toolPath .. "/linux/" .. _name
	elseif os.is("osx") then
		toolPath = toolPath .. "/darwin/" .. _name
	end
	return toolPath
end

function flatten(t)
	t = t or {}
	local tmp = {}
	for si,sv in ipairs(t) do
			if type( sv ) == "table" then
		for _,v in ipairs(sv) do
			table.insert(tmp, v)
		end
			elseif type( sv ) == "string" then
				table.insert( tmp, sv )
			end
		t[si] = nil
	end
	for _,v in ipairs(tmp) do
		table.insert(t, v)
	end
end

--
function getProjectTempIncludePath(_project)
   mkdir(getSolutionBaseDir() .. "/include/" .. _project)
   return getSolutionBaseDir() .. "/include/" .. _project
end

-- read file contents
function file_read(_file)
    local f = io.open(_file, "r")
	if f == nil then return "" end
    local content = f:read("*all")
    f:close()
    return content
end

-- Check if a file exists
function file_exists(file)
	if file == nil then return false end
	local ok, err, code = os.rename(file, file)
	if not ok then
		if code == 13 then -- Permission denied, but it exists
			return true
		end
	end
	return ok, err
end

-- Check if a file is a directory
-- "/" works on both Unix and Windows
function file_isdir(path)
	return file_exists(path.."/")
end

-- 
function mkdir(_dirname)
	if os.isdir(_dirname) then return end
	local dir = _dirname
	if os.is("windows") then
		dir = string.gsub( _dirname, "([/]+)", "\\" )
	else
		dir = string.gsub( _dirname, "\\\\", "\\" )
	end

	if not file_isdir(dir) then
		if not os.is("windows") then
			os.execute("mkdir -p " .. dir)
		else
			os.execute("mkdir " .. dir)
		end
	end
end

--
function recreateDir(_path)
	rmdir(_path)
	mkdir(_path)
end

--
function file_get_time(filepath)
	if os.is("windows") then
		local pipe = io.popen('dir /4/tw "'..filepath..'"')
		local output = pipe:read"*a"
		pipe:close()
		return output:match"\n(%d.-:%S*)"
	else
		local pipe = io.popen("stat -c %Y " .. filepath)
		local last_modified = pipe:read("*a")
		pipe:close()
		return last_modified
	end
end

-- 
function getFileNameNoExtFromPath( path )
	local i = 0
	local lastSlash = 0
	local lastPeriod = 0
	local returnFilename
	while true do
		i = string.find( path, "/", i+1 )
		if i == nil then break end
		lastSlash = i
	end

	i = 0
	while true do
		i = string.find( path, "%.", i+1 )
		if i == nil then break end
		lastPeriod = i
	end

	if lastPeriod < lastSlash then
		returnFilename = path:sub( lastSlash + 1 )
	else
		returnFilename = path:sub( lastSlash + 1, lastPeriod - 1 )
	end

	return returnFilename
end

function setupCMakeProjectHeaders(srcPath, dstPath, replacePairs)
	-- replace cmakedefine with define
	-- replace strings with known values
	-- remove all instances of '@'

	os.copyfile(srcPath, dstPath);

	local sedCommand = getToolForHost("sed")

	if replacePairs ~= nil then
    for _,replacePair in ipairs(replacePairs) do
		os.execute(sedCommand .. " -i s/'" .. replacePair[1] .. "'/'" .. replacePair[2] .. "'/g " .. dstPath)
	end
	end

	os.execute(sedCommand .. " -i s/cmakedefine/define/g " .. dstPath)
	os.execute(sedCommand .. " -i s/@//g " .. dstPath)
end
