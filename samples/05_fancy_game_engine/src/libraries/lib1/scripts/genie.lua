--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

newoption { trigger = "zidar-path", description = "Path to zidar" }
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile("lib1.lua")

solution "lib1"
	setPlatforms()
	projectAdd_lib1()
