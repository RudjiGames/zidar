--
-- Copyright 2025 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--

function addProject_game(_name)

	if _ACTION == nil then return end

	group ("games")
	project (_name)

		language    "C++"
		uuid		( os.uuid(project().name) )

		configuration { "retail" }
			kind		"WindowedApp"
		configuration { "debug or release" }
			kind		"ConsoleApp"
		configuration {}

		project().path = path.getabsolute(	getProjectPath(_name, ProjectPath.Dir) or 
											getProjectPath(_name, ProjectPath.Root)) .. "/"

		local srcFilesPath = project().path .. "src/"
		
		local	sourceFiles = mergeTables(	{ srcFilesPath .. "**.cpp" },
											{ srcFilesPath .. "**.h" } )
		files  { sourceFiles }
		
		addPCH( srcFilesPath, project().name )
		
		includedirs	{ srcFilesPath }
	
		flags { Flags_Cmd }

		assert(loadfile(RTM_SCRIPTS_DIR .. "configurations.lua"))(	sourceFiles,
																	false,	-- IS_LIBRARY
																	false,	-- IS_SHARED_LIBRARY
																	false,	-- COPY_QT_DLLS
																	false,	-- WITH_QT
																	true	-- EXECUTABLE
																	)

		addDependencies(project().name, { {"rapp", "bgfx"} })
end
