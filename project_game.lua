--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

function addProject_game(_name)

	group	( "games" )
	project ( _name )

		-- not supported on Xcode ?
		project().kind = "ConsoleApp"
		kind	( project().kind )

		configuration { "retail" }
			kind "WindowedApp"
		configuration {}

		uuid	( os.uuid(project().name) )
		flags	{ Flags_Cmd }

		local projectPath	= projectGetPath(_name)
		local srcFilesPath	= projectPath .. "/src"
		local sourceFiles	= projectSourceFilesWildcard(srcFilesPath)

		if projectIsCPP(sourceFiles) then
			language	"C++"
		else
			language	"C"
		end					

		files		{ sourceFiles }
		includedirs	{ srcFilesPath }
		libdirs		{ srcFilesPath }
		addPCH( srcFilesPath, project().name )

		projectConfig()
		addDependencies(project().name, { "bgfx" })
end
