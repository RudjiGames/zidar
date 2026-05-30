--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

function addProject_3rdParty_lib(_name, _libFiles, _exceptions, _language)

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

		-- An explicit language wins over auto-detection: the sources for a
		-- 3rd party lib may be cloned on demand during generation, in which
		-- case projectIsCPP() can run before the files exist on disk and
		-- wrongly fall back to "C" (which makes MSVC compile .cpp as C).
		if _language then
			language	( _language )
		elseif projectIsCPP(_libFiles) then
			language	"C++"
		else
			language	"C"
		end

		projectConfig()
		addDependencies(project().name)
end
