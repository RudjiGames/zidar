--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

function projectDependencies_04_Qt_app_using_a_library() 
	return { "02_hello_library" }
end

function projectAdd_04_Qt_app_using_a_library() 
	addProject_qt("04_Qt_app_using_a_library")
end
