--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

function addProject_cmd(_name)

	group	( "tools_cmd" )
	project ( _name )
	
		project().kind = "ConsoleApp"

		kind	( project().kind )
		uuid	( os.uuid(project().name) )
		flags	{ Flags_Cmd }

		local projectPath	= projectGetPath(_name)
		local rootPath		= path.getabsolute(path.join(projectPath, "../"))
		local sourceFiles	= projectSourceFilesWildcard(projectPath)

		if projectIsCPP(sourceFiles) then
			language	"C++"
		else
			language	"C"
		end

		files		{ sourceFiles }
		includedirs	{ rootPath, projectPath, path.join(rootPath, _name .. "/src") }

		addPCH( projectPath, project().name )

		projectConfig()
		addDependencies(project().name)
end
