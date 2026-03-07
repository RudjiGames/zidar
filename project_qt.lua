--
-- Copyright 2025 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--

function addProject_qt(_name, _libProjNotExe, _includes, _prebuildcmds, _extraQtModules)

	if _ACTION == nil then return end

	_libProjNotExe	= _libProjNotExe or false
	_includes		= _includes or {}
	_prebuildcmds	= _prebuildcmds or {}
	
	if _libProjNotExe == true then
		group ("toollibs")
	else
		group ("tools")
	end
	
	project (_name)

		local projKind = "WindowedApp"
		if _libProjNotExe == true then
			projKind = "StaticLib"
		end
	
		language	"C++"
		kind		( projKind )
		uuid		( os.uuid(project().name) )

		project().path = getProjectPath(project().name, ProjectPath.Root) .. "/" .. _name .. "/"

		local	sourceFiles = mergeTables(	{ project().path .. "inc/**.h" },
											{ project().path .. "src/**.cpp" },
											{ project().path .. "src/**.h" },
											{ project().path .. "src/**.ui" },
											{ project().path .. "src/**.qrc" },
											{ project().path .. "src/**.ts" } )

		if getTargetOS() == "windows" then
			sourceFiles = mergeTables(sourceFiles, { project().path .. "src/**.rc" })
		end

		files  { sourceFiles }

		mocFiles	=	{ os.matchfiles( project().path .. "inc/**.h"), os.matchfiles( project().path .. "src/**.h") }
		uiFiles		=	{ os.matchfiles( project().path .. "src/**.ui") }
		qrcFiles	= 	{ os.matchfiles( project().path .. "src/**.qrc") }
		tsFiles		= 	{ os.matchfiles( project().path .. "src/**.ts") }

		libsToLink	=	mergeTables({ "Core", "Gui", "Widgets", "Network"}, _extraQtModules)

		addPCH( project().path .. "src/", project().name )

		configuration {}

		includedirs
		{ 
			getProjectPath(project().name, ProjectPath.Root),
			project().path .. "src/",
			_includes
		}

		flags { Flags_QtTool }
		if os.is("linux") then
			buildoptions { "-fPIC" }
		end

		local outputDir = RTM_OUT_DIR
		if _libProjNotExe == true then
			outputDir = RTM_LIB_DIR
		end

		assert(loadfile(RTM_SCRIPTS_DIR .. "configurations.lua"))(	sourceFiles,
																	false,					-- IS_LIBRARY
																	false,					-- IS_SHARED_LIBRARY
																	true,					-- COPY_QT_DLLS
																	true,					-- WITH_QT
																	_libProjNotExe == false -- EXECUTABLE
																	)
		for _,cmd in ipairs( _prebuildcmds ) do
			prebuildcommands {cmd}
		end
		
		addDependencies(_name)
end

