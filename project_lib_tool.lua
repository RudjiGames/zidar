--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

function addProject_lib_tool(_name, _libName)

	group	( "libs-tools" )
	project ( _name .. "_" .. _libName )

		project().kind = "ConsoleApp"

		kind	( project().kind )
		uuid	( os.uuid(project().name) )
		flags	{ Flags_Libraries }

		local projectPath = projectGetPath(project().name)
		local sourceFiles = projectSourceFilesWildcard(projectPath)

		files	{ sourceFiles }

		if projectIsCPP(sourceFiles) then
			language	"C++"
		else
			language	"C"
		end			

		local withBGFX = projectRequiresBGFX( projectPath )

		includedirs
		{ 
			projectPath .. "/src",
			projectPath .. "/tools" .. "/" .. _name,
		}

		addPCH( projectPath, project().name )

		local dependencies = { _name }

		if withBGFX then
			dependencies[#dependencies + 1] = "bgfx"
		end

		projectConfig()
		addDependencies(project().name, dependencies)
end
