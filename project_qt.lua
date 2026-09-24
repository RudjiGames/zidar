--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

local g_qtProjectFilesCache = {}

local g_qtHeaderUsesQObjectCache = {}

local function qtHeaderUsesQObject(_file)
	local cached = g_qtHeaderUsesQObjectCache[_file]
	if cached ~= nil then
		return cached
	end

	local headerSrc = fileRead(_file)
	cached = headerSrc:find("Q_OBJECT", 1, true) ~= nil
	g_qtHeaderUsesQObjectCache[_file] = cached
	return cached
end

local function getQtProjectFiles(_projectPath, _walk)
	local cached = g_qtProjectFilesCache[_projectPath]
	if cached ~= nil then
		return cached.mocFiles, cached.uiFiles, cached.qrcFiles, cached.tsFiles
	end

	_walk = _walk or projectWalkFiles(_projectPath)
	local srcPath  = _projectPath .. "/src"
	local headers  = mergeTables(filterFilesByExtension(_walk, { ".h" }, _projectPath .. "/inc"), filterFilesByExtension(_walk, { ".h" }, srcPath))
	local uiFiles  = filterFilesByExtension(_walk, { ".ui" }, srcPath)
	local qrcFiles = filterFilesByExtension(_walk, { ".qrc" }, srcPath)
	local tsFiles  = filterFilesByExtension(_walk, { ".ts" }, srcPath)

	local mocFiles = {}
	for _, header in ipairs(headers) do
		if qtHeaderUsesQObject(header) then
			table.insert(mocFiles, header)
		end
	end

	g_qtProjectFilesCache[_projectPath] = {
		mocFiles = mocFiles,
		uiFiles  = uiFiles,
		qrcFiles = qrcFiles,
		tsFiles  = tsFiles,
	}

	return mocFiles, uiFiles, qrcFiles, tsFiles
end

-- _extraQtModules : extra Qt modules to LINK (and copy the DLL for), beyond Core/Gui/Widgets/Network.
-- _extraQtDlls    : extra Qt DLLs to COPY next to the exe but NOT link - transitive runtime dependencies
--                   (e.g. Qt6OpenGL, loaded by Qt6OpenGLWidgets) that the app does not reference directly.
function addProject_qt(_name, _libraryType, _includes, _prebuildcmds, _extraQtModules, _extraQtDlls)

	if _libraryType ~= nil then
		group ( vpathStringFromLibraryType(_libraryType) )
	else
		group ( "tools" )
	end
	
	project ( _name )

		project().kind = "WindowedApp"
		if _libraryType == LibraryType.Tool then
			project().kind = "StaticLib"
		end
	
		language	"C++"

		kind	( project().kind )
		uuid	( os.uuid(project().name) )
		flags	{ Flags_QtTool }

		local projectPath = projectGetPath(project().name)
		local sourceFiles, _, walks = projectSourceFiles( projectPath )
		local walk        = walks[projectPath]
		local libsToLink  =	mergeTables({ "Core", "Gui", "Widgets", "Network"}, _extraQtModules)

		local extraExtensions = { ".ui", ".qrc", ".ts" }
		if getTargetOS() == "windows" then
			extraExtensions[#extraExtensions + 1] = ".rc"
		end
		sourceFiles = mergeTables(sourceFiles, filterFilesByExtension(walk, extraExtensions, projectPath .. "/src"))

		files  { sourceFiles }

		local mocFiles, uiFiles, qrcFiles, tsFiles = getQtProjectFiles(projectPath, walk)
		
		addPCH( projectPath .. "/src/", project().name )

		configuration {} -- should remove ?

		_includes = _includes or {}
		includedirs	{ 
			path.getdirectory(projectGetScriptPath(project().name)),
			projectPath .. "/src",
			_includes
		}

		if os.is("linux") then
			buildoptions { "-fPIC" }
		end

		_prebuildcmds = _prebuildcmds or {}
		for _,cmd in ipairs( _prebuildcmds ) do
			prebuildcommands { cmd }
		end

		 -- true = isQtProject, adds extra defines and flags for qt projects
		projectConfig(true, mocFiles, uiFiles, qrcFiles, tsFiles, libsToLink, _extraQtDlls)
		addDependencies(project().name)
end
