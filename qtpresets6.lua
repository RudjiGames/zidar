--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

qt = {}
qt.version = "6" -- default Qt version

-- Qt root is per target bitness: 64-bit builds use QTDIR, 32-bit builds use
-- QTDIRx86. Qt has no multi-arch install layout - the two are separate trees
-- with identically named DLLs - so a single variable cannot serve both.
function qtEnvVarName(_is64bit)
	return _is64bit and "QTDIR" or "QTDIRx86"
end

-- Qt root for the target bitness with trailing slashes stripped, or nil if the
-- variable is unset or empty.
local function qtRootForTarget(_is64bit)
	local qtPath = os.getenv(qtEnvVarName(_is64bit))
	if qtPath == nil then
		return nil
	end
	while string.sub(qtPath, -1) == "/" or string.sub(qtPath, -1) == "\\" do
		qtPath = string.sub(qtPath, 1, -2)
	end
	if qtPath == "" then
		return nil
	end
	return qtPath
end

-- qtConfigure() runs once per project per configuration, so warn at most once
-- per variable instead of repeating the same line for every Qt project.
local g_qtMissingWarned = {}
local function qtWarnMissingOnce(_varName, _qtPath)
	if g_qtMissingWarned[_varName] then
		return
	end
	g_qtMissingWarned[_varName] = true
	local why = (_qtPath == nil)
		and (_varName .. " is not set")
		or  (_varName .. ' points at "' .. _qtPath .. '", which is not a directory')
	printWarning(why .. " - 32-bit Qt projects will be generated, but building them will fail until it is set.")
end

local function qtFileSize(_path)
	local f = io.open(_path, "rb")
	if not f then
		return nil
	end
	local size = f:seek("end")
	f:close()
	return size
end

-- Staging a Qt DLL used to be "copy only if the destination is missing", which
-- was safe while a single QTDIR meant the staged DLL could never be the wrong
-- one. With separate QTDIR / QTDIRx86 roots - or after upgrading either Qt - a
-- stale DLL from a previous version would survive forever, and the app would
-- load a Qt6Core of one version next to a Qt6Svg of another. Qt modules only
-- resolve against their own version, so that surfaces as an unhelpful "DLL is
-- missing" at startup. Size is a cheap proxy for "different build": exact only
-- in the sense that two different Qt builds of the same DLL are essentially
-- never byte-identical in length.
local function qtCopyIfDifferent(_source, _dest)
	local destSize = qtFileSize(_dest)
	if destSize ~= nil and destSize == qtFileSize(_source) then
		return
	end
	os.mkdir(path.getdirectory(_dest))
	os.copyfile(_source, _dest)
end

function qtConfigure( _platform, _configuration, _mocfiles, _uifiles, _qrcfiles, _tsfiles, _libsToLink, _copyDynamicLibraries, _is64bit, _dbgPrefix, _isFirstConfig, _copyOnlyDlls )

	_copyOnlyDlls = _copyOnlyDlls or {}

		local RG_QT_LIB_PREFIX		= "Qt" .. qt.version
		local QT_PREBUILD_LUA_PATH	= 'lua "' .. path.getabsolute(RG_ZIDAR_DIR .. "/qtprebuild.lua") .. '"'
		local sourcePath			= projectGetPath(project().name) .. "/src"

		local QT_ENV_VAR	= qtEnvVarName(_is64bit)
		local QT_PATH		= qtRootForTarget(_is64bit)

		-- A missing 32-bit Qt must not break project generation. Generation stays
		-- complete - moc/uic/rcc/lrelease prebuild steps, generated file paths,
		-- include/lib dirs and link lines are all still emitted - so the solution
		-- loads and the 64-bit configurations build normally. Only an actual 32-bit
		-- build fails, and it fails against a path that names the variable to set.
		-- A missing 64-bit Qt stays fatal: QTDIR is required by every Qt project.
		local qtAvailable = (QT_PATH ~= nil) and os.isdir(QT_PATH)
		if not qtAvailable then
			if _is64bit then
				printError("The " .. QT_ENV_VAR .. " environment variable must be set to the Qt root directory to use qtpresets6.lua", true)
			end
			qtWarnMissingOnce(QT_ENV_VAR, QT_PATH)
			QT_PATH = QT_ENV_VAR .. "-NOT-SET"
		end

		local QT_MOC_FILES_PATH = path.join(sourcePath, "../.qt/qt_moc")
		local QT_UI_FILES_PATH	= path.join(sourcePath, "../.qt/qt_ui")
		local QT_QRC_FILES_PATH = path.join(sourcePath, "../.qt/qt_qrc")
		local QT_TS_FILES_PATH	= path.join(sourcePath, "../.qt/qt_qm")

		if _isFirstConfig then
			os.mkdir( QT_MOC_FILES_PATH )
			os.mkdir( QT_UI_FILES_PATH )
			os.mkdir( QT_QRC_FILES_PATH )
			os.mkdir( QT_TS_FILES_PATH )
		end

		local addedFiles = {}

		local projName = project().name

		-- Qt tool invocations embed QT_PATH, which now differs per bitness, so they
		-- are collected here and emitted further down under a {_platform,
		-- _configuration} filter. The files{} calls in these loops must NOT become
		-- platform-scoped: they run for the first platform only (_isFirstConfig) and
		-- the generated sources belong to every platform.
		local qtPrebuildCmds = {}

		-- Set up Qt pre-build steps and add the future generated file paths to the pkg
		for _,file in ipairs( _mocfiles ) do
			local absFile = path.getabsolute(file)
			local mocFilePath = path.getabsolute(QT_MOC_FILES_PATH .. "/" .. path.getbasename(file) .. "_moc.cpp")
			table.insert(qtPrebuildCmds, QT_PREBUILD_LUA_PATH .. ' -moc "' .. absFile .. '" "' .. QT_PATH .. '" "' .. projName .. '" "' .. mocFilePath .. '"')
			if _isFirstConfig then
				files { file, mocFilePath }
				table.insert(addedFiles, file)
			end
		end

		for _,file in ipairs( _uifiles ) do
			local absFile = path.getabsolute(file)
			local uiFilePath = path.getabsolute(QT_UI_FILES_PATH .. "/" .. path.getbasename(file) .. "_ui.h")
			table.insert(qtPrebuildCmds, QT_PREBUILD_LUA_PATH .. ' -uic "' .. absFile .. '" "' .. QT_PATH .. '" "' .. projName .. '" "' .. uiFilePath .. '"')
			if _isFirstConfig then
				files { file, uiFilePath }
				table.insert(addedFiles, uiFilePath)
			end
		end

		for _,file in ipairs( _qrcfiles ) do
			local absFile = path.getabsolute(file)
			local qrcFilePath = path.getabsolute(QT_QRC_FILES_PATH .. "/" .. path.getbasename(file) .. "_qrc.cpp")
			table.insert(qtPrebuildCmds, QT_PREBUILD_LUA_PATH .. ' -rcc "' .. absFile .. '" "' .. QT_PATH .. '" "' .. projName .. '" "' .. qrcFilePath .. '"')
			if _isFirstConfig then
				files { file, qrcFilePath }
				table.insert(addedFiles, qrcFilePath)
			end
		end

		for _,file in ipairs( _tsfiles ) do
			local absFile = path.getabsolute(file)
			local tsFilePath = path.getabsolute(QT_TS_FILES_PATH .. "/" .. path.getbasename(file) .. "_ts.qm")
			table.insert(qtPrebuildCmds, QT_PREBUILD_LUA_PATH .. ' -ts "' .. absFile .. '" "' .. QT_PATH .. '" "' .. projName .. '" "' .. tsFilePath .. '"')
			if _isFirstConfig then
				files { file, tsFilePath }
				table.insert(addedFiles, tsFilePath)
			end
		end				

		local binDir = getBuildDirRoot(_platform, _configuration)

		-- Everything from here down depends on QT_PATH, so it must be scoped to this
		-- PLATFORM as well as this configuration. commonConfig() already filters on
		-- {_platform, _configuration}; qtConfigure() used to filter on the
		-- configuration alone. That was harmless while both platforms shared a single
		-- QTDIR (the values were identical, merely emitted twice), but with QTDIR and
		-- QTDIRx86 it would put 32-bit include/lib paths and moc commands into the
		-- 64-bit configuration.
		configuration { _platform, _configuration }

		prebuildcommands { qtPrebuildCmds }

		includedirs	{ QT_PATH .. "/include" }

		-- Qt's own headers are not warning-clean at our /W4: qnumeric.h trips C4702 (unreachable code). This GENie
		-- can't emit <ExternalWarningLevel>, so /external:W0 would only fight the toolset's default /external:W4 and
		-- spew D9025. Instead just disable the specific low-value C4702 for Qt projects (a warning DISABLE, not a
		-- level, so no D9025). Scoped to vs* since /wd is MSVC-only; other rg_* libraries keep C4702.
		configuration { _platform, _configuration, "vs*" }
			buildoptions { "/wd4702" }	-- unreachable code in Qt headers (qnumeric.h)
		configuration { _platform, _configuration }

		local libsDirectory = QT_PATH .. "/lib"
		if os.is("macosx") then
			linkoptions { "-F " .. libsDirectory }
			includedirs { libsDirectory }
		else
			libdirs { libsDirectory }
		end

		if os.is("windows") then

			-- qtAvailable gate: these os.copyfile calls run at GENERATION time, not
			-- build time, so without a real Qt root they would silently copy nothing
			-- (or noisily fail) while generating. Skipping keeps generation clean; the
			-- DLLs land on the next generate once the variable points somewhere real.
			if _copyDynamicLibraries and qtAvailable then

				local destPath = binDir
				destPath = string.gsub( destPath, "([/]+)", "\\" ) .. '\\bin\\'

				-- The "platforms" plugin dir is invariant of lib, so create it once before the copy loop
				-- (guarded by a non-empty lib list to match the original loop-body semantics: the dir was
				-- only ever created when at least one iteration ran) instead of re-issuing an idempotent
				-- mkdir syscall for every linked Qt library.
				if #_libsToLink > 0 then
					os.mkdir(destPath .. "/platforms")
				end

				for _, lib in ipairs( _libsToLink ) do
					local libname =  RG_QT_LIB_PREFIX .. lib  .. _dbgPrefix .. '.dll'
					qtCopyIfDifferent( QT_PATH .. '/bin/' .. libname, destPath .. libname )
				end

				-- Runtime-only Qt DLLs: copied to the output but NOT linked. These are transitive runtime
				-- dependencies (e.g. Qt6OpenGL, pulled in at load time by Qt6OpenGLWidgets) that the app does
				-- not reference directly, so they must ship next to the exe but stay off the link line.
				-- Passed in via addProject_qt's _extraQtDlls argument.
				for _, lib in ipairs( _copyOnlyDlls ) do
					local libname =  RG_QT_LIB_PREFIX .. lib  .. _dbgPrefix .. '.dll'
					qtCopyIfDifferent( QT_PATH .. '/bin/' .. libname, destPath .. libname )
				end

				local otherDLLs = {
					{ name = "platforms\\qwindows" .. _dbgPrefix, srcPrefix = "/plugins/" },
					{ name = "platforms\\qminimal" .. _dbgPrefix, srcPrefix = "/plugins/" },
					-- SVG plugins: QIcon(":/...svg") needs the ICON ENGINE (iconengines/qsvgicon) and QImage/QPixmap
					-- svg loading needs the IMAGE FORMAT (imageformats/qsvg). Qt6Svg.dll alone is NOT enough - without
					-- qsvgicon every .svg QIcon is silently null (toolbar buttons/docks lose their icons).
					{ name = "iconengines\\qsvgicon" .. _dbgPrefix, srcPrefix = "/plugins/" },
					{ name = "imageformats\\qsvg" .. _dbgPrefix, srcPrefix = "/plugins/" },
					-- JPEG imageformat: capture screenshots are JPEG chunks the viewer decodes with QImage::fromData
					-- (screenshot strip). PNG is built into Qt6Gui, JPEG is NOT - without qjpeg the strip is blank.
					{ name = "imageformats\\qjpeg" .. _dbgPrefix, srcPrefix = "/plugins/" },
				}

				if _ACTION:find("gmake") then
					local libName = _is64bit and "libstdc++_64-6" or "libstdc++-6"
					otherDLLs[#otherDLLs + 1] = { name = libName, srcPrefix = "/bin/" }
				end

				for i=1, #otherDLLs, 1 do
					local libname =  otherDLLs[i].name .. '.dll'
					qtCopyIfDifferent( QT_PATH .. otherDLLs[i].srcPrefix .. libname, destPath .. '\\' .. libname )
				end
			end

			-- QT_NO_DEPRECATED_WARNINGS silences C4996 emitted from Qt's own headers for APIs Qt
			-- has marked deprecated-for-Qt7 (e.g. QGuiApplication/QApplication::compressEvent), which
			-- would otherwise warn in every Qt translation unit on newer toolsets (VS2026).
			defines { "QT_THREAD_SUPPORT", "QT_USE_QSTRINGBUILDER", "QT_NO_DEPRECATED_WARNINGS" }

			includedirs	{ QT_PATH .. "/qtwinextras/include" }
				
			if _ACTION:find("vs") then
					-- Qt rcc doesn't support forced header inclusion - preventing us to do PCH in visual studio (gcc accepts files that don't include pch)
					buildoptions( "/FI" .. '"' .. project().name .. "_pch.h" .. '"' .. " " )
					-- 4127 conditional expression is constant
					-- 4275 non dll-interface class 'stdext::exception' used as base for dll-interface class 'std::bad_cast'
					buildoptions( "/wd4127 /wd4275 /Zc:__cplusplus /std:c++20 /permissive-" ) 
			end

			for _, lib in ipairs( _libsToLink ) do
				local libFile = libsDirectory .. "/" .. RG_QT_LIB_PREFIX .. lib
				links( libFile .. _dbgPrefix )
			end
	
		elseif os.is("linux") then

			-- check if X11Extras is needed
			local extrasLib = QT_PATH .. "/lib/lib" .. RG_QT_LIB_PREFIX .. "X11Extras.a"
			if os.isfile(extrasLib) == true then
				_libsToLink = mergeTables(_libsToLink, {"X11Extras"})
			end

			-- should run this first (path may vary):
			-- export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/home/user/Qt5.7.0/5.7/gcc_64/lib/pkgconfig
			-- lfs support is required too: sudo luarocks install luafilesystem
			local qtLinks = RG_QT_LIB_PREFIX .. table.concat( _libsToLink, " " .. RG_QT_LIB_PREFIX )

			-- pkg-config output is deterministic for a given Qt lib set, but qtConfigure() runs per project/config,
			-- so the two popen() spawns fired on every configuration. Memoize by the lib-set key so each unique set
			-- shells out at most once per generation (a failed lookup caches nil too, matching the old retry result).
			_qtPkgConfigCache = _qtPkgConfigCache or {}
			local pkg = _qtPkgConfigCache[qtLinks]
			if not pkg then
				local libPipe  = io.popen( "pkg-config --libs "   .. qtLinks, 'r' )
				local flagPipe = io.popen( "pkg-config --cflags " .. qtLinks, 'r' )
				pkg = { libs = libPipe:read( '*line' ), flags = flagPipe:read( '*line' ) }
				libPipe:close()
				flagPipe:close()
				_qtPkgConfigCache[qtLinks] = pkg
			end

			buildoptions { pkg.flags }
			linkoptions { pkg.libs }

		elseif os.is("macosx") then
			-- buildoptions { qtFlags }
			for _,lib in ipairs(_libsToLink) do
				print("Linking framework: " .. libsDirectory .. "/Qt" .. lib .. ".framework")
				-- make symbolic link to header files directory
				-- (skipped without a real Qt root: this runs at generation time)
				if qtAvailable then
					os.execute("ln -s -f " .. libsDirectory .. "/Qt" .. lib .. ".framework/Versions/A/Headers/ " .. QT_PATH .. "/include/Qt" .. lib)
				end
				linkoptions {
					"-framework " .. "Qt" .. lib,
				}
			end
		end

	configuration {}
	return addedFiles
end
