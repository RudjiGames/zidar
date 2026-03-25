--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

newoption { trigger = "zidar-path", description = "Path to zidar" }
print(_OPTIONS["zidar-path"] .. "/zidar.lua")
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile("04_Qt_app_using_a_library.lua")

solution "Qt_app_using_a_library"
	setPlatforms()
	projectAdd("04_Qt_app_using_a_library")
