--
-- Zidar - Build system
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

--
-- Embedded shader support.
--
-- A project declares the shaders it wants compiled into C headers with
-- addShaders{ ... } (called BEFORE the project's projectConfig()/addProject_*),
-- and zidar regenerates the matching "<name>.bin.h" next to each "<name>.sc"
-- during project generation (genie time), so the build itself has no dependency
-- on shaderc, lua or cat. If shaderc cannot be found the step is skipped and the
-- committed .bin.h headers are used as-is, so builds never break for the lack of
-- the tool. Projects that don't call addShaders are completely unaffected.
--

-- Host-tool sub-directory under zidar/tools/bin for the machine running genie.
local function hostToolDir()
	local host = os.get()
	if host == "windows" then return "windows" end
	if host == "macosx"  then return "darwin"  end
	if host == "linux"   then return "linux"   end
	return host
end

-- Resolves the shaderc executable, or nil if it cannot be found.
-- Order: RG_SHADERC env override, then the binary shipped in zidar/tools/bin.
local function shadercPath()
	local exe = os.is("windows") and "shaderc.exe" or "shaderc"

	local override = os.getenv("RG_SHADERC")
	if override and os.isfile(override) then
		return override
	end

	local shipped = RG_ZIDAR_DIR .. "/tools/bin/" .. hostToolDir() .. "/" .. exe
	if os.isfile(shipped) then
		return shipped
	end

	return nil
end

-- Per-shader-type list of { profile, suffix, platform, optimization } variants,
-- matching bgfx's canonical embedded-shader recipe (scripts/shader-embeded.mk).
local function shaderVariants(_type)
	if _type == "compute" then
		return {
			{ p = "430",    s = "glsl", plat = "linux",   o = nil },
			{ p = nil,      s = "essl", plat = "android", o = nil },
			{ p = "spirv",  s = "spv",  plat = "linux",   o = nil },
			{ p = "wgsl",   s = "wgsl", plat = "linux",   o = nil },
			{ p = "s_5_0",  s = "dxbc", plat = "windows", o = "1" },
			{ p = "s_6_0",  s = "dxil", plat = "windows", o = "1" },
			{ p = "metal",  s = "mtl",  plat = "ios",     o = "3" },
		}
	end
	-- vertex / fragment
	return {
		{ p = "120",    s = "glsl", plat = "linux",   o = nil },
		{ p = "100_es", s = "essl", plat = "android", o = nil },
		{ p = "spirv",  s = "spv",  plat = "linux",   o = nil },
		{ p = "wgsl",   s = "wgsl", plat = "linux",   o = nil },
		{ p = "s_5_0",  s = "dxbc", plat = "windows", o = "3" },
		{ p = "s_6_0",  s = "dxil", plat = "windows", o = "3" },
		{ p = "metal",  s = "mtl",  plat = "ios",     o = "3" },
	}
end

local function readFile(_path)
	local f = io.open(_path, "rb")
	if not f then return nil end
	local data = f:read("*a")
	f:close()
	return data
end

local function quote(_s)
	return '"' .. _s .. '"'
end

-- Converts to the host's native path separators (cmd on Windows dislikes '/').
local function native(_s)
	if os.is("windows") then return _s:gsub("/", "\\") end
	return _s
end

-- Command prefix that puts _dir (bgfx's redistributable DXC/d3dcompiler dlls)
-- on PATH so shaderc can load them when compiling the dxbc/dxil variants.
local function withDllPath(_dir)
	if os.is("windows") then
		return 'set "PATH=' .. native(_dir) .. ';%PATH%" & '
	end
	return 'PATH="' .. _dir .. ':$PATH" '
end

-- Registers shader source files (glob patterns allowed) for the current project.
-- Must be called before the project's projectConfig()/addProject_* so the
-- generated .bin.h headers exist by the time the sources that #include them are
-- compiled. Safe to call multiple times.
function addShaders(_patterns)
	_shaderFiles = _shaderFiles or {}
	_shaderFilesSeen = _shaderFilesSeen or {}   -- dedup set parallel to _shaderFiles; reset with it in shaderConfigure
	for _, pattern in ipairs(_patterns) do
		for _, file in ipairs(os.matchfiles(pattern)) do
			-- Overlapping patterns (or repeat calls) previously inserted the same file more than once, so
			-- shaderConfigure then re-ran shaderc on it for every duplicate. Insert each file at most once.
			if not _shaderFilesSeen[file] then
				_shaderFilesSeen[file] = true
				table.insert(_shaderFiles, file)
			end
		end
	end
end

-- Regenerates the embedded-shader headers registered for _projectName.
-- Runs at genie time; clears _shaderFiles so registrations never leak between
-- projects. No-op (and no error) when no shaders were registered or shaderc is
-- unavailable.
function shaderConfigure(_projectName)

	local shaderFiles = _shaderFiles
	_shaderFiles = nil
	_shaderFilesSeen = nil   -- reset the dedup set with the file list so registrations never leak between projects

	if shaderFiles == nil or #shaderFiles == 0 then
		return
	end

	local shaderc = shadercPath()
	if shaderc == nil then
		printWarning("shaderc not found - keeping committed embedded shaders for '" .. _projectName ..
			"'. Set RG_SHADERC or add it to zidar/tools/bin/" .. hostToolDir() .. "/.")
		return
	end

	local bgfxPath = find3rdPartyProject("bgfx")
	if bgfxPath == nil then
		printWarning("bgfx not found - cannot regenerate embedded shaders for '" .. _projectName .. "'.")
		return
	end

	local includes = " -i " .. quote(bgfxPath .. "src/")
	if os.isdir(bgfxPath .. "examples/common/") then
		includes = includes .. " -i " .. quote(bgfxPath .. "examples/common/")
	end

	local dllPrefix = withDllPath(bgfxPath .. "tools/bin/" .. hostToolDir())
	local shadercExe = native(shaderc)
	local devnull = os.is("windows") and " >nul 2>&1" or " >/dev/null 2>&1"

	for _, file in ipairs(shaderFiles) do
		local base = path.getname(file):gsub("%.sc$", "")

		local shaderType
		if     base:sub(1, 3) == "vs_" then shaderType = "vertex"
		elseif base:sub(1, 3) == "fs_" then shaderType = "fragment"
		elseif base:sub(1, 3) == "cs_" then shaderType = "compute"
		end

		if shaderType and base ~= "varying.def" then
			local dir       = path.getdirectory(file)
			local binHeader = dir .. "/" .. base .. ".bin.h"
			local tmp       = binHeader .. ".tmp"
			local varying   = dir .. "/varying.def.sc"

			local varyingArg = ""
			if os.isfile(varying) then
				varyingArg = " --varyingdef " .. quote(varying)
			end

			local pieces   = {}
			local complete = true
			for _, v in ipairs(shaderVariants(shaderType)) do
				local cmd = dllPrefix .. quote(shadercExe) .. includes ..
					" --type " .. shaderType ..
					" --platform " .. v.plat ..
					(v.p and (" -p " .. v.p) or "") ..
					(v.o and (" -O " .. v.o) or "") ..
					varyingArg ..
					" -f " .. quote(file) ..
					" -o " .. quote(tmp) ..
					" --bin2c " .. base .. "_" .. v.s ..
					devnull

				local data = os.execute(cmd) and readFile(tmp)
				if data and #data > 0 then
					table.insert(pieces, data)
				else
					complete = false
					printWarning("shaderc could not build " .. base .. " (" .. v.s .. ").")
					break
				end
			end
			os.remove(tmp)

			-- Strictly additive: only replace the committed header when the whole
			-- variant set compiled, so a missing tool or transient failure can
			-- never truncate or partially overwrite a known-good header.
			if complete then
				-- pssl is supplied externally on the platforms that need it.
				table.insert(pieces, "extern const uint8_t* "  .. base .. "_pssl;\n")
				table.insert(pieces, "extern const uint32_t " .. base .. "_pssl_size;\n")
				local out = io.open(binHeader, "wb")
				if out then
					out:write(table.concat(pieces))
					out:close()
					printInfo("\xE2\x96\xB6 embedded shader : " .. base .. ".bin.h", Color.Green)
				else
					printWarning("Could not write " .. binHeader)
				end
			else
				printWarning("Keeping committed header for " .. base .. ".bin.h (incomplete shaderc output).")
			end
		end
	end
end
