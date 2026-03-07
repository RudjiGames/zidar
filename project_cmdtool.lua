--
-- Copyright 2025 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--

function addProject_cmd(_name)

	if _ACTION == nil then return end

	group ("tools_cmd")

	project (_name)
	
		language	"C++"
		kind		"ConsoleApp"
		uuid		( os.uuid(project().name) )

		local path = getProjectPath(_name)
		local rootPath = path .. "../"

		project().path = path ..  "/src/"

		local	sourceFiles = mergeTables(	{ project().path .. "**.cpp" },
											{ project().path .. "**.h" } )
		files  { sourceFiles }

		addPCH( project().path, project().name )

		includedirs { rootPath, project().path }

		flags { Flags_Cmd }

		assert(loadfile(RTM_SCRIPTS_DIR .. "configurations.lua"))(	sourceFiles,
																	false,	-- IS_LIBRARY
																	false,	-- IS_SHARED_LIBRARY
																	false,	-- COPY_QT_DLLS
																	false,	-- WITH_QT
																	true	-- EXECUTABLE
																	)
		addDependencies(_name)
end
