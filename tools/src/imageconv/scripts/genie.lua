--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

dofile "../../../../zidar.lua"
dofile "imageconv.lua"

solution "imageconv"
	configurations { "debug", "release", "retail" }
	setPlatforms()

	projectAdd( "imageconv" )
	startproject "imageconv"
