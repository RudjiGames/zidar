--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

qt = {}
qt.version = "6" -- default Qt version

function qtConfigure( _platform, _configuration, _mocfiles, _uifiles, _qrcfiles, _tsfiles, _libsToLink, _copyDynamicLibraries, _is64bit, _dbgPrefix, _isFirstConfig )
	 
		local RG_QT_LIB_PREFIX		= "Qt" .. qt.version
		local QT_PREBUILD_LUA_PATH	= 'lua "' .. path.getabsolute(RG_ZIDAR_DIR .. "/qtprebuild.lua") .. '"'
		local sourcePath			= projectGetPath(project().name) .. "/src"

		-- Defaults
		local QT_PATH = os.getenv("QTDIR")
    	if QT_PATH == nil then
	    	printErrorAndExit("The QTDIR environment variable must be set to the Qt root directory to use qtpresets6.lua")
	   	end

		-- strip trailing slash if present for consistent path handling
		if string.sub(QT_PATH, -1) == "/" or string.sub(QT_PATH, -1) == "\\" then
			QT_PATH = string.sub(QT_PATH, 1, -2)
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

		-- Set up Qt pre-build steps and add the future generated file paths to the pkg
		for _,file in ipairs( _mocfiles ) do
			local absFile = path.getabsolute(file)
			local mocFilePath = path.getabsolute(QT_MOC_FILES_PATH .. "/" .. path.getbasename(file) .. "_moc.cpp")
			prebuildcommands { QT_PREBUILD_LUA_PATH .. ' -moc "' .. absFile .. '" "' .. QT_PATH .. '" "' .. projName .. '" "' .. mocFilePath .. '"' }
			if _isFirstConfig then
				files { file, mocFilePath }
				table.insert(addedFiles, file)
			end
		end

		for _,file in ipairs( _uifiles ) do
			local absFile = path.getabsolute(file)
			local uiFilePath = path.getabsolute(QT_UI_FILES_PATH .. "/" .. path.getbasename(file) .. "_ui.h")
			prebuildcommands { QT_PREBUILD_LUA_PATH .. ' -uic "' .. absFile .. '" "' .. QT_PATH .. '" "' .. projName .. '" "' .. uiFilePath .. '"' }
			if _isFirstConfig then
				files { file, uiFilePath }
				table.insert(addedFiles, uiFilePath)
			end
		end

		for _,file in ipairs( _qrcfiles ) do
			local absFile = path.getabsolute(file)
			local qrcFilePath = path.getabsolute(QT_QRC_FILES_PATH .. "/" .. path.getbasename(file) .. "_qrc.cpp")
			prebuildcommands { QT_PREBUILD_LUA_PATH .. ' -rcc "' .. absFile .. '" "' .. QT_PATH .. '" "' .. projName .. '" "' .. qrcFilePath .. '"' }
			if _isFirstConfig then
				files { file, qrcFilePath }
				table.insert(addedFiles, qrcFilePath)
			end
		end

		for _,file in ipairs( _tsfiles ) do
			local absFile = path.getabsolute(file)
			local tsFilePath = path.getabsolute(QT_TS_FILES_PATH .. "/" .. path.getbasename(file) .. "_ts.qm")
			prebuildcommands { QT_PREBUILD_LUA_PATH .. ' -ts "' .. absFile .. '" "' .. QT_PATH .. '" "' .. projName .. '" "' .. tsFilePath .. '"' }
			if _isFirstConfig then
				files { file, tsFilePath }
				table.insert(addedFiles, tsFilePath)
			end
		end				

		local binDir = getBuildDirRoot(_platform, _configuration)
	
		includedirs	{ QT_PATH .. "/include" }

		local libsDirectory = QT_PATH .. "/lib"
		if os.is("macosx") then
			linkoptions { "-F " .. libsDirectory }
			includedirs { libsDirectory }
		else
			libdirs { libsDirectory }
		end

		if os.is("windows") then

			if _copyDynamicLibraries then

				local destPath = binDir
				destPath = string.gsub( destPath, "([/]+)", "\\" ) .. '\\bin\\'

				for _, lib in ipairs( _libsToLink ) do
					local libname =  RG_QT_LIB_PREFIX .. lib  .. _dbgPrefix .. '.dll'
					local source = QT_PATH .. '/bin/' .. libname
					local dest = destPath .. libname
					os.mkdir(destPath .. "/platforms")
					if not os.isfile(dest) then
						os.copyfile( source, dest )
					end
				end

				local otherDLLs = {
					{ name = "platforms\\qwindows" .. _dbgPrefix, srcPrefix = "/plugins/" },
					{ name = "platforms\\qminimal" .. _dbgPrefix, srcPrefix = "/plugins/" },
				}

				if _ACTION:find("gmake") then
					local libName = _is64bit and "libstdc++_64-6" or "libstdc++-6"
					otherDLLs[#otherDLLs + 1] = { name = libName, srcPrefix = "/bin/" }
				end

				for i=1, #otherDLLs, 1 do
					local libname =  otherDLLs[i].name .. '.dll'
					local source = QT_PATH .. otherDLLs[i].srcPrefix .. libname
					local dest = destPath .. '\\' .. libname
					if not os.isfile(dest) then
						os.mkdir(path.getdirectory(dest))
						os.copyfile( source, dest )
					end
				end
			end

			defines { "QT_THREAD_SUPPORT", "QT_USE_QSTRINGBUILDER" }

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

			local qtLibs  = "pkg-config --libs " .. qtLinks
			local qtFlags = "pkg-config --cflags " .. qtLinks
			local libPipe = io.popen( qtLibs, 'r' )
			local flagPipe= io.popen( qtFlags, 'r' )

			qtLibs = libPipe:read( '*line' )
			qtFlags = flagPipe:read( '*line' )
			libPipe:close()
			flagPipe:close()

			buildoptions { qtFlags }
			linkoptions { qtLibs }

		elseif os.is("macosx") then
			-- buildoptions { qtFlags }
			for _,lib in ipairs(_libsToLink) do
				print("Linking framework: " .. libsDirectory .. "/Qt" .. lib .. ".framework")
				-- make symbolic link to header files directory
				os.execute("ln -s -f " .. libsDirectory .. "/Qt" .. lib .. ".framework/Versions/A/Headers/ " .. QT_PATH .. "/include/Qt" .. lib)
				linkoptions {
					"-framework " .. "Qt" .. lib,
				}
			end
		end

	configuration {}
	return addedFiles
end
