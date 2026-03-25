--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

function addProject_3rdParty_lib(_name, _libFiles, _exceptions)

	group	( "3rd" )
	project ( _name )

		project().kind = "StaticLib"

		kind	( project().kind )
		uuid	( os.uuid(project().name) )
		flags	{ Flags_ThirdParty }
		files 	{ _libFiles }

		if not (_exceptions or false) then
			flags { "NoExceptions" }
		end

		if projectIsCPP(_libFiles) then
			language	"C++"
		else
			language	"C"
		end	

		projectConfig()
		addDependencies(project().name)
end
