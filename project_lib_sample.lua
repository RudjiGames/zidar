--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

function addProject_lib_sample(_name, _sampleName)

	group	( "samples" )
	project ( _sampleName )

		project().kind = "ConsoleApp"

		kind	( project().kind )
		uuid	( os.uuid(project().name) )
		flags	{ Flags_Libraries }

		local libsPath = path.getdirectory(projectGetPath(_name))

		local projectPath = libsPath .. "/" .. _name

		local srcFilesPath	= projectPath .. "/samples/" .. _sampleName
		local incFilesPath	= srcFilesPath .. "/**.h"
		local sourceFiles	= projectSourceFilesWildcard(srcFilesPath)
		files  { sourceFiles }

		if projectIsCPP(sourceFiles) then
			language	"C++"
		else
			language	"C"
		end					

		local withBGFX	= projectRequiresBGFX( srcFilesPath )
		includedirs
		{ 
			projectPath .. "/samples",
			incFilesPath,
		}
		
		addPCH( srcFilesPath, project().name )

		local dependencies = { _name }

		if withBGFX then
			dependencies[#dependencies + 1] = "bgfx"
		end

		projectConfig()
		addDependencies(project().name, dependencies)
end
