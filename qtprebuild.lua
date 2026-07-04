#!/usr/local/bin/lua5.1

--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

local qtDirectory = ""
qtDirectory = arg[3] or qtDirectory

lua_version = _VERSION:match(" (5%.[123])$") or "5.1"
windows		= package.config:sub( 1, 1 ) == "\\"
nativeSlash = "/"
if windows then
	nativeSlash	= "\\"
end

--
local function file_isdir(path)
	local ok, err, code = os.rename(path .. "/", path .. "/")
	if not ok then
		if code == 13 then return true end
		return false
	end
	return true
end

--
local function file_exists(file)
	if file == nil then return false end
	if file_isdir(file) then return false end
	local f = io.open(file, "r")
	if f then f:close() return true end
	return false
end

--
local function mkdir(_dirname)
	local dir = _dirname
	if windows then
		dir = string.gsub( _dirname, "([/]+)", "\\" )
	else
		dir = string.gsub( _dirname, "\\\\", "\\" )
	end

	if not file_isdir(dir) then
		if not windows then
			os.execute('mkdir -p "' .. dir .. '"  > /dev/null')
		else
			os.execute('mkdir "' .. dir .. '" > nul')
		end
	end
end
--
local outputFilePath = arg[5]

local function BuildErrorWarningString( line, isError, message, code )
	if windows then
		return string.format( "qtprebuild.lua(%i): %s %i: %s", line, isError and "error" or "warning", code, message )
	else
		return string.format( "qtprebuild.lua:%i: %s: %s", line, isError and "error" or "warning", message )
	end
end

--Make sure there are at least 2 arguments
if not ( #arg >= 2 ) then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, "There must be at least 2 arguments supplied", 2 ) ); io.stdout:flush()
	return
end

--Checks that the first argument is either "-moc", "-uic", or "-rcc"
if not ( arg[1] == "-moc" or arg[1] == "-uic" or arg[1] == "-rcc"  or arg[1] == "-ts" ) then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[The first argument must be "-moc", "-uic", "-rcc" or "-ts"]], 3 ) ); io.stdout:flush()
	return
end

--Make sure input file exists
if not file_exists(arg[2]) then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[The supplied input file ]]..arg[2]..[[, does not exist]], 4 ) ); io.stdout:flush()
	return
end

local function getExe(_name)
	local ext = windows and ".exe" or ""
	local binPath = qtDirectory .. nativeSlash .. "bin" .. nativeSlash .. _name
	local libexecPath = qtDirectory .. nativeSlash .. "libexec" .. nativeSlash .. _name
	if file_exists(libexecPath .. ext) then return libexecPath end
	if file_exists(binPath .. ext) then return binPath end
	return binPath
end

local QtToolExe = {}
QtToolExe.moc		= getExe("moc")
QtToolExe.uic		= getExe("uic")
QtToolExe.qrc		= getExe("rcc")
QtToolExe.ts		= getExe("lrelease")

local function shellQuoteWindows(_s)
	return "'" .. string.gsub(_s, "'", "''") .. "'"
end

local function shellQuotePosix(_s)
	return "'" .. string.gsub(_s, "'", "'\\''") .. "'"
end

local function trim(_s)
	return (_s and string.match(_s, "^%s*(.-)%s*$")) or nil
end

local lfs_ok, lfs = pcall(require, "lfs")

local function file_get_time(_filepath)
	if not file_exists(_filepath) then
		return nil
	end

	-- LuaFileSystem reads the mtime with ZERO child processes. The old code spawned a powershell (Windows) or
	-- stat (posix) PER FILE, so a .qrc with hundreds of embedded resources fired hundreds of serial process
	-- cold-starts on every rebuild - minutes of latency that looks like a hung build. mtimes are only ever
	-- compared against each other (input vs output vs deps), so units/epoch don't matter as long as every value
	-- in a run comes from the SAME source; hence lfs is used exclusively when present (a nil attribute -> nil ->
	-- treated as out-of-date, the safe result). The popen probe stays only as the fallback for a lua without lfs.
	if lfs_ok then
		return lfs.attributes(_filepath, "modification")
	end

	local pipe = nil
	if windows then
		pipe = io.popen('powershell -NoProfile -Command "(Get-Item -LiteralPath ' .. shellQuoteWindows(_filepath) .. ').LastWriteTimeUtc.Ticks"')
	else
		local quoted = shellQuotePosix(_filepath)
		pipe = io.popen('(stat -f %m ' .. quoted .. ' 2>/dev/null || stat -c %Y ' .. quoted .. ' 2>/dev/null)')
	end

	if not pipe then
		return nil
	end

	local output = pipe:read("*a")
	pipe:close()
	return tonumber(trim(output))
end

local function pathJoin(_dir, _leaf)
	if not _dir or _dir == "" then
		return _leaf
	end
	local last = string.sub(_dir, -1)
	if last == "/" or last == "\\" then
		return _dir .. _leaf
	end
	return _dir .. nativeSlash .. _leaf
end

local function getPath(str, sep)
	if not str then
		return nil
	end
	if sep then
		return str:match("(.*" .. sep .. ")")
	end
	return str:match("^(.*[/\\])")
end

local function qrc_is_up_to_date(_inputFileName, _outputFileName)
	local outputTime = file_get_time(_outputFileName)
	local inputTime = file_get_time(_inputFileName)
	if not outputTime or not inputTime or inputTime > outputTime then
		return false
	end

	local qrcDir = getPath(_inputFileName) or ""
	local qrcFile = io.open(_inputFileName, "r")
	if not qrcFile then
		return false
	end

	local qrcData = qrcFile:read("*a")
	qrcFile:close()

	for relPath in string.gmatch(qrcData, "<file[^>]*>%s*([^<]+)%s*</file>") do
		local depPath = trim(relPath)
		if depPath and depPath ~= "" then
			local depTime = file_get_time(pathJoin(qrcDir, depPath))
			if not depTime or depTime > outputTime then
				return false
			end
		end
	end

	return true
end

local function file_is_upToDate(_inputFileName, _outputFileName, _mode)
	local outputTime = file_get_time(_outputFileName)
	local inputTime = file_get_time(_inputFileName)
	if not outputTime or not inputTime then
		return false
	end
	if inputTime > outputTime then
		return false
	end
	if _mode == "-rcc" then
		return qrc_is_up_to_date(_inputFileName, _outputFileName)
	end
	return true
end

local function getFileNameNoExtNoPathFromPath( path )
	return string.sub(path, 1, path:find("%.[^.]*$") - 1):match("[^\\/]+$")
end

local outputDir = outputFilePath and getPath(outputFilePath) or ""

local runProgram = function(command)
	local result = 1
	if lua_version == "5.3" then
		local value, type
		value, type, result = os.execute(command)
	else
		result = os.execute(command)
	end
	if windows then
		return result == 0
	end
	return result
end

if outputDir ~= "" then
	mkdir( outputDir )
end

-- All four tool modes generate arg[2] -> outputFilePath and share the SAME up-to-date test (mode = arg[1]). Run it
-- ONCE here and bail silently when nothing changed, so an up-to-date rebuild no longer prints a "Generating <type>
-- for ..." line for every file it then immediately skips (the per-branch checks below were AFTER their print).
if file_is_upToDate(arg[2], outputFilePath, arg[1]) then
	return
end

if arg[1] == "-moc" then
	print("Generating MOC file for " .. arg[2])
	local fullMOCPath = QtToolExe.moc.." \""..arg[2].. "\" -I \"" .. getPath(arg[2]) .. "\" -o \"" .. outputFilePath .."\" -f\"".. arg[4] .. "_pch.h\" -f\"" .. arg[2] .. "\""
	if windows then
		fullMOCPath = '""'..QtToolExe.moc..'" "'..arg[2].. '" -I "' .. getPath(arg[2]) .. '" -o "' .. outputFilePath ..'"' .. " -f".. arg[4] .. "_pch.h -f" .. arg[2] .. '"'
	end
	if false == runProgram(fullMOCPath) then
		print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[MOC Failed to generate ]]..outputFilePath, 5 ) ); io.stdout:flush()
	else
		io.stdout:flush()
	end
elseif arg[1] == "-uic" then
	print("Generating UI header for " .. arg[2])
	local fullUICPath = QtToolExe.uic.." \""..arg[2].."\" -o \""..outputFilePath.."\""
	if windows then
		fullUICPath = '""'..QtToolExe.uic..'" "'..arg[2]..'" -o "'..outputFilePath..'""'
	end
	if false == runProgram(fullUICPath) then
		print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[UIC Failed to generate ]]..outputFilePath, 7 ) ); io.stdout:flush()
	else
		io.stdout:flush()
	end
elseif arg[1] == "-rcc" then
	print("Compiling Resource file for " .. arg[2])
	local fullRCCPath = QtToolExe.qrc.." -name \""..getFileNameNoExtNoPathFromPath( arg[2] ).."\" \""..arg[2].."\" -o \""..outputFilePath.."\""
	if windows then
		fullRCCPath = '""'..QtToolExe.qrc..'" -name "'..getFileNameNoExtNoPathFromPath( arg[2] )..'" "'..arg[2]..'" -o "'..outputFilePath..'""'
	end
	if false == runProgram(fullRCCPath) then
		print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[RCC Failed to generate ]]..outputFilePath, 6 ) ); io.stdout:flush()
	else
		io.stdout:flush()
	end
elseif arg[1] == "-ts" then
	print("Generating Translation file for " .. arg[2])
	local fullTSPath = QtToolExe.ts.." \""..arg[2].."\""
	if windows then
		fullTSPath = '""' .. QtToolExe.ts .. '" "' .. arg[2] .. '""'
	end
	if false == runProgram( fullTSPath) then
		print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[Translation Failed to generate ]]..outputFilePath, 7 ) ); io.stdout:flush()
	else
		io.stdout:flush()
	end
end
