--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Dear ImGui: Bloat-free Graphical User interface for C++ with minimal dependencies
-- https://github.com/ocornut/imgui

local params		= { ... }
local IMGUI_ROOT	= params[1]

local IMGUI_FILES = {
	IMGUI_ROOT .. "/imconfig.h",
	IMGUI_ROOT .. "/imgui.cpp",
	IMGUI_ROOT .. "/imgui.h",
	IMGUI_ROOT .. "/imgui_draw.cpp",
	IMGUI_ROOT .. "/imgui_internal.h",
	IMGUI_ROOT .. "/stb_rect_pack.h",
	IMGUI_ROOT .. "/stb_textedit.h",
	IMGUI_ROOT .. "/stb_truetype.h",
}

function projectExtraConfig_imgui()
	includedirs { IMGUI_ROOT }
end

function projectAdd_imgui()
	addProject_3rdParty_lib("imgui", IMGUI_FILES)
end


function projectSource_imgui()
	return "https://github.com/ocornut/imgui"
end
