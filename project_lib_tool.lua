--
-- Copyright 2025 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--

function addProject_lib_tool(_name, _toolName)

	if _ACTION == nil then return end

	group ("libs-tools")

	project (_toolName)

		language	"C++"
		kind		"ConsoleApp"
		uuid		( os.uuid(project().name) )

		project().path = getProjectPath(_name, ProjectPath.Dir) .. "/tools/" .. _toolName .. "/"

		local	sourceFiles = mergeTables(	{ project().path .. "**.cpp" },
											{ project().path .. "**.h" } )
		files  { sourceFiles }

		local withBGFX = false
		for _,file in ipairs( sourceFiles ) do
			local SourceCode = file_read(file);
			if SourceCode:find("#define RAPP_WITH_BGFX") then -- NB: a single space character between 'define' and 'RAPP_WITH_BGFX'
				withBGFX = true
				break
			end
		end

		addPCH( project().path, project().name )

		includedirs { project().path .. "/src" }

		flags { Flags_Libraries }

		assert(loadfile(RTM_SCRIPTS_DIR .. "configurations.lua"))(	sourceFiles,
																	false,	-- IS_LIBRARY
																	false,	-- IS_SHARED_LIBRARY
																	false,	-- COPY_QT_DLLS
																	false,	-- WITH_QT
																	true	-- EXECUTABLE
																	)

		local dependencies = {}
		if _name ~= "rapp" then
			dependencies = mergeTables(dependencies, { _name })
		end

		if withBGFX then
			dependencies = mergeTables(dependencies, {{"rapp", "bgfx"}})
		else
			dependencies = mergeTables(dependencies, {"rapp"})
		end

		addDependencies(project().name, dependencies )
end
