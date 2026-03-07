--
-- Copyright 2025 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--

function addProject_lib(_name, _libType, _shared, _nameAppend, _disablePCH)

	if _ACTION == nil then return end

	if _libType == Lib.Tool then
		group ("libs_tools")
	elseif _libType == Lib.Game then
		group ("libs_game")
	else
		group ("libs")
	end

	_nameAppend = _nameAppend or ""

	project (_name .. _nameAppend)

		LastLibLoaded = project().name

		_libType		= _libType or Lib.Runtime
		_shared			= _shared or false
		_disablePCH		= _disablePCH or false

		local libKind = "StaticLib"
		if _shared then
			libKind = "SharedLib"
		end
		
		language    "C++"
		kind        ( libKind )
		uuid		( os.uuid(project().name) )

		local libsPath = getProjectPath(_name, ProjectPath.Root)

		local projectPath = libsPath .. "/" .. _name

		project().path = projectPath

		local srcFilesPath  = projectPath .. "/src/"
		local incFilesPath  = projectPath .. "/inc"

		local	sourceFiles = mergeTables(	{ srcFilesPath .. "**.cpp" },
											{ srcFilesPath .. "**.cxx" },
											{ srcFilesPath .. "**.c" },
											{ srcFilesPath .. "**.h" },
											{ incFilesPath .. "**.h" } )
		files  { sourceFiles }
	
		local targetOS = getTargetOS()
		if targetOS == "ios" or targetOS == "osx" then
			files  { srcFilesPath .. "**.mm" }
		end

		excludes { projectPath .. "/test/**.*" }
		excludes { projectPath .. "/samples/**.*" }

		if _disablePCH ~= true then
			addPCH( srcFilesPath, _name )
		end

		shaderFiles	= os.matchfiles( srcFilesPath .. "**.sc" )

		includedirs	{
			libsPath, 
			incFilesPath,
			srcFilesPath			
		}

		addIncludePath(_name, projectPath .. "/3rd/")

		flags { Flags_Libraries }
		
		assert(loadfile(RTM_SCRIPTS_DIR .. "configurations.lua"))(	sourceFiles,
																	true,		-- IS_LIBRARY
																	_shared,	-- IS_SHARED_LIBRARY
																	false,		-- COPY_QT_DLLS
																	false,		-- WITH_QT
																	false,		-- EXECUTABLE
																	_name
																	)

		addDependencies(project().name)
		addLibProjects(project().name)
end
