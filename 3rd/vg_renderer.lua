--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- A vector graphics renderer for bgfx
-- https://github.com/RudjiGames/vg_renderer.git

local params			= { ... }
local VGRENDERER_ROOT	= params[1]

local VGRENDERER_FILES = {
	VGRENDERER_ROOT .. "/src/**.cpp",
	VGRENDERER_ROOT .. "/src/**.h",
	VGRENDERER_ROOT .. "/include/**.h",
	VGRENDERER_ROOT .. "/include/**.inl"
}

function projectDependencies_vg_renderer()
	return { "bgfx", "bx", "libtess2" }
end

function projectExtraConfig_vg_renderer()
	includedirs { VGRENDERER_ROOT .. "/include" }
end

function projectExtraConfigExecutable_vg_renderer()
	includedirs { VGRENDERER_ROOT .. "/include" }
end

function projectAdd_vg_renderer()
	addProject_3rdParty_lib("vg_renderer", VGRENDERER_FILES)
end

function projectSource_vg_renderer()
	return "https://github.com/RudjiGames/vg_renderer.git"
end
