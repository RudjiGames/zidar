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
			os.execute("mkdir -p " .. dir .. "  > /dev/null")
		else
			os.execute("mkdir " .. dir .. " > nul")
		end
	end
end
--
local sourceDir = ""
if arg[2] ~= nil then
	local projName = arg[4]
	sourceDir = arg[2]:match("(.*" .. projName .. ")") .. "/src"
end

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

local QtOutDirectory = {}
QtOutDirectory.main	= sourceDir .. "/../.qt"
QtOutDirectory.moc	= sourceDir .. "/../.qt/qt_moc"
QtOutDirectory.uic	= sourceDir .. "/../.qt/qt_ui"
QtOutDirectory.qrc	= sourceDir .. "/../.qt/qt_qrc"
QtOutDirectory.ts	= sourceDir .. "/../.qt/qt_qm"

local function getExe(_name)
	local exeName = _name
	 if windows then exeName = qtDirectory .. nativeSlash .. "bin" .. nativeSlash .. exeName end
	return exeName
end

local QtToolExe = {}
QtToolExe.moc		= getExe("moc")
QtToolExe.uic		= getExe("uic")
QtToolExe.qrc		= getExe("rcc")
QtToolExe.ts		= getExe("lrelease")

mkdir( QtOutDirectory.main )

local function file_get_time(filepath)
	if windows then
		local pipe = io.popen('dir /4/tw "'..filepath..'"')
		local output = pipe:read"*a"
		pipe:close()
		return output:match"\n(%d.-:%S*)"
	else
		local pipe = io.popen("stat -c %Y " .. filepath)
		local last_modified = pipe:read("*a")
		pipe:close()
		return last_modified
	end
end

local function file_is_upToDate(outputFileName) 
	--if file_exists(outputFileModTime) and ( inputFileModTime < outputFileModTime ) then
		--print( outputFileName.." is up-to-date, not regenerating" )
		--io.stdout:flush()
		--return true
	--else
		--print( outputFileName .. " is out of date, regenerating" )
	--end
	return false
end

local function getFileNameNoExtNoPathFromPath( path )
	return string.sub(path, 1, path:find("%.[^.]*$") - 1):match("[^\\/]+$")
end

local getPath=function(str,sep)
    sep=sep or'/'
    return str:match("(.*"..sep..")")
end

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

if arg[1] == "-moc" then
	mkdir( QtOutDirectory.moc )
	print("Generating MOC file for " .. arg[2])
	local outputFileName = QtOutDirectory.moc .. nativeSlash .. getFileNameNoExtNoPathFromPath( arg[2] ) .. "_moc.cpp"
	if file_is_upToDate(outputFileName) then return end
	local fullMOCPath = QtToolExe.moc.." \""..arg[2].. "\" -I \"" .. getPath(arg[2]) .. "\" -o \"" .. outputFileName .."\" -f\"".. arg[4] .. "_pch.h\" -f\"" .. arg[2] .. "\""
	if windows then
		fullMOCPath = '""'..QtToolExe.moc..'" "'..arg[2].. '" -I "' .. getPath(arg[2]) .. '" -o "' .. outputFileName ..'"' .. " -f".. arg[4] .. "_pch.h -f" .. arg[2] .. '"'
	end
	if false == runProgram(fullMOCPath) then
		print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[MOC Failed to generate ]]..outputFileName, 5 ) ); io.stdout:flush()
	else
		io.stdout:flush()
	end
elseif arg[1] == "-uic" then
	mkdir( QtOutDirectory.uic )
	print("Generating UI header for " .. arg[2])
	local outputFileName = QtOutDirectory.uic .. nativeSlash .. getFileNameNoExtNoPathFromPath( arg[2] ) .. "_ui.h"
	if file_is_upToDate(outputFileName) then return end
	local fullUICPath = QtToolExe.uic.." \""..arg[2].."\" -o \""..outputFileName.."\""
	print(fullUICPath)
	if windows then
		fullUICPath = '""'..QtToolExe.uic..'" "'..arg[2]..'" -o "'..outputFileName..'""'
	end
	if false == runProgram(fullUICPath) then
		print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[UIC Failed to generate ]]..outputFileName, 7 ) ); io.stdout:flush()
	else
		io.stdout:flush()
	end
elseif arg[1] == "-rcc" then
	mkdir( QtOutDirectory.qrc )
	print("Compiling Resource file for " .. arg[2])
	local outputFileName = QtOutDirectory.qrc .. nativeSlash .. getFileNameNoExtNoPathFromPath( arg[2] ) .. "_qrc.cpp"

	if file_is_upToDate(outputFileName) then return end

	local fullRCCPath = QtToolExe.qrc.." -name \""..getFileNameNoExtNoPathFromPath( arg[2] ).."\" \""..arg[2].."\" -o \""..outputFileName.."\""
	if windows then
		fullRCCPath = '""'..QtToolExe.qrc..'" -name "'..getFileNameNoExtNoPathFromPath( arg[2] )..'" "'..arg[2]..'" -o "'..outputFileName..'""'
	end

	if false == runProgram(fullRCCPath) then
		print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[RCC Failed to generate ]]..outputFileName, 6 ) ); io.stdout:flush()
	else
		io.stdout:flush()
	end
elseif arg[1] == "-ts" then
	mkdir( QtOutDirectory.ts )
	print("Generating Translation file for " .. arg[2])
	local outputFileName = QtOutDirectory.ts .. nativeSlash .. getFileNameNoExtNoPathFromPath( arg[2] ) .. "_ts.qm"
	if file_is_upToDate(outputFileName) then return end
	local fullTSPath = QtToolExe.ts.." \""..arg[2].."\""
	if windows then
		fullTSPath = '""' .. QtToolExe.ts .. '" "' .. arg[2] .. '""'
	end
	if false == runProgram( fullTSPath) then
		print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[Translation Failed to generate ]]..outputFileName, 7 ) ); io.stdout:flush()
	else
		io.stdout:flush()
	end		
end
