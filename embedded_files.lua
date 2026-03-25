--
-- Zidar - Build system
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

function shaderConfigure( _platform, _configuration, _projectName )

	if _shaderFiles == nil then
		return
	end

	local SHADER_PREBUILD_LUA_PATH	= '"' .. RG_ROOT_DIR .. "/zidar/embedded_shader_prebuild.lua" .. '"'

	flatten( _shaderFiles )

	local LUAEXE = "lua "
	local shaderc = RG_ROOT_DIR .. "/tools/bgfx/shaderc"
	if os.is("windows") then
		shaderc = RG_ROOT_DIR .. "/tools/bgfx/shaderc.exe"
		LUAEXE = "lua.exe "
	end

	local function starts_with(str, start) return str:sub(1, #start) == start end

	-- Set up shader pre-build steps
	for _,file in ipairs( _shaderFiles ) do
		local scFileBase = path.getname(file)

		if scFileBase ~= "varying.def" then

			local srcFile = path.getabsolute(file)

			local commandSuffix = srcFile .. ' ' .. shaderc .. ' ' .. RG_ROOT_DIR .. "/3rd/bgfx/src/ ".. RG_ROOT_DIR .. "/3rd/bgfx/examples/common/"

			-- vertex shader
			if starts_with(scFileBase, "vs_") then
				prebuildcommands { LUAEXE .. SHADER_PREBUILD_LUA_PATH .. ' -vs ' .. commandSuffix }
			end

			if starts_with(scFileBase, "fs_") then
				prebuildcommands { LUAEXE .. SHADER_PREBUILD_LUA_PATH .. ' -fs ' .. commandSuffix }
			end

			if starts_with(scFileBase, "cs_") then
				prebuildcommands { LUAEXE .. SHADER_PREBUILD_LUA_PATH .. ' -cs ' .. commandSuffix }
			end
		end
	end

	configuration {}
	return {}
end
