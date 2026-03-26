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

local function getQtProjectFiles(_projectPath)
	local cached = g_qtProjectFilesCache[_projectPath]
	if cached ~= nil then
		return cached.mocFiles, cached.uiFiles, cached.qrcFiles, cached.tsFiles
	end

	local headers  = mergeTables(os.matchfiles(_projectPath .. "/inc/**.h"), os.matchfiles(_projectPath .. "/src/**.h"))
	local uiFiles  = os.matchfiles(_projectPath .. "/src/**.ui")
	local qrcFiles = os.matchfiles(_projectPath .. "/src/**.qrc")
	local tsFiles  = os.matchfiles(_projectPath .. "/src/**.ts")

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

function addProject_qt(_name, _libraryType, _includes, _prebuildcmds, _extraQtModules)

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
		local sourceFiles = projectSourceFilesWildcard( projectPath )
		local libsToLink  =	mergeTables({ "Core", "Gui", "Widgets", "Network"}, _extraQtModules)

		sourceFiles = mergeTables(sourceFiles,	{ projectPath .. "/src/**.ui"  },
												{ projectPath .. "/src/**.qrc" },
												{ projectPath .. "/src/**.ts"  } )

		if getTargetOS() == "windows" then
			sourceFiles = mergeTables( sourceFiles, { projectPath .. "/src/**.rc" })
		end

		files  { sourceFiles }

		local mocFiles, uiFiles, qrcFiles, tsFiles = getQtProjectFiles(projectPath)
		
		addPCH( projectPath .. "/src/", project().name )

		configuration {} -- should remove ?

		_includes = _includes or {}
		includedirs	{ 
			projectGetScriptPath(project().name),
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
		projectConfig(true, mocFiles, uiFiles, qrcFiles, tsFiles, libsToLink)
		addDependencies(project().name)
end
