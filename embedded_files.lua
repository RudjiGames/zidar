--
-- Copyright 2025 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--

function shaderConfigure( _platform, _configuration, _projectName, _shaderFiles )

	if _shaderFiles == nil then
		return
	end

	local SHADER_PREBUILD_LUA_PATH	= '"' .. RTM_ROOT_DIR .. "build/embedded_shader_prebuild.lua" .. '"'

	flatten( _shaderFiles )

	local LUAEXE = "lua "
	local shaderc = RTM_ROOT_DIR .. "tools/bgfx/shaderc"
	if os.is("windows") then
		shaderc = RTM_ROOT_DIR .. "tools/bgfx/shaderc.exe"
		LUAEXE = "lua.exe "
	end

	local addedFiles = {}

	-- Set up shader pre-build steps
	for _,file in ipairs( _shaderFiles ) do
		local scFile = stripExtension(file)
		local scFileBase = path.getbasename(file)

		if scFileBase ~= "varying.def" then

			local outFile = path.getabsolute(scFile .. '.bin.h')
			--local includesDirs = " -i " .. RTM_ROOT_DIR .. "3rd/bgfx/src/" .. " -i " .. RTM_ROOT_DIR .. "3rd/bgfx/examples/common/"

			local srcFile = path.getabsolute(file)
			local dstFile = path.getabsolute(outFile)

			-- vertex shader
			if string.find(scFileBase, "vs_") ~= nil then
				prebuildcommands { LUAEXE .. SHADER_PREBUILD_LUA_PATH .. ' -vs ' .. srcFile .. ' ' .. shaderc .. ' ' .. RTM_ROOT_DIR .. "3rd/bgfx/src/ ".. RTM_ROOT_DIR .. "3rd/bgfx/examples/common/" }
			end

			if string.find(scFileBase, "fs_") ~= nil then
				prebuildcommands { LUAEXE .. SHADER_PREBUILD_LUA_PATH .. ' -fs ' .. srcFile .. ' ' .. shaderc .. ' ' .. RTM_ROOT_DIR .. "3rd/bgfx/src/ ".. RTM_ROOT_DIR .. "3rd/bgfx/examples/common/" }
			end

			if string.find(scFileBase, "cs_") ~= nil then
				prebuildcommands { LUAEXE .. SHADER_PREBUILD_LUA_PATH .. ' -cs ' .. srcFile .. ' ' .. shaderc .. ' ' .. RTM_ROOT_DIR .. "3rd/bgfx/src/ ".. RTM_ROOT_DIR .. "3rd/bgfx/examples/common/" }
			end
		end
	end

	configuration {}
	return addedFiles
end
