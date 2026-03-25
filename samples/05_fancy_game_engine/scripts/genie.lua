--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

newoption { trigger = "zidar-path", description = "Path to zidar" }
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile "../src/libraries/libraries.lua"
dofile "../src/tools/tools.lua"
dofile "../src/games/games.lua"

solution "fancy_game_engine"
	setPlatforms()
	projectAdd("lib1")
	projectAdd("lib2")
	projectAdd("toolCmdLine")
	projectAdd("toolQt")
	projectAdd("game1")
	projectAdd("game2")
