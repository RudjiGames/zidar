--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

function addProject_lib_test(_name)

	group	( "tests" )
	project ( _name .. "_test" )

		project().kind = "ConsoleApp"

		kind	( project().kind )
		uuid	( os.uuid(project().name) )
		flags	{ Flags_Tests }

		local projectPath		= projectGetPath(_name)
		local projectPathTests	= projectPath .. "/tests"

		includedirs {	projectPath .. "/include",
						projectPathTests }

		local sourceFiles	= projectSourceFilesWildcard(projectPathTests)
		local isCPP			= projectIsCPP(sourceFiles)

		if isCPP then
			language	"C++"
		else
			language	"C"
		end					

		files { sourceFiles }
		
		addPCH( projectPathTests, project().name )

		projectConfig()

	if isCPP then	
		addDependencies(project().name, { "unittest-cpp", _name })
	else
		addDependencies(project().name, { "unity", _name }) -- NB: unity is a C unit testing framework,
	end
end
