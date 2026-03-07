--
-- Copyright 2025 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--
-- Based on Qt4 build script from Kyle Hendricks <kyle.hendricks@gentex.com> 
-- and Josh Lareau <joshua.lareau@gentex.com>
--

qt = {}
qt.version = "6" -- default Qt version

RTM_QT_FILES_PATH_MOC	= "../.qt/qt_moc"
RTM_QT_FILES_PATH_UI	= "../.qt/qt_ui"
RTM_QT_FILES_PATH_QRC	= "../.qt/qt_qrc"
RTM_QT_FILES_PATH_TS	= "../.qt/qt_qm"

QT_LIB_PREFIX		= "Qt" .. qt.version

function qtConfigure( _platform, _configuration, _projectName, _mocfiles, _qrcfiles, _uifiles, _tsfiles, _libsToLink, _copyDynamicLibraries, _is64bit, _dbgPrefix )

		local sourcePath			= getProjectPath(_projectName) .. "/src/"
		local QT_PREBUILD_LUA_PATH	= 'lua "' .. RTM_ROOT_DIR .. "build/qtprebuild.lua" .. '"'

		-- Defaults
		local QT_PATH = os.getenv("QTDIR")
    	if QT_PATH == nil then
	    	print ("ERROR: The QTDIR environment variable must be set to the Qt root directory to use qtpresets6.lua")
		    os.exit()
    	end

		-- ensure path ends with slash for concatenation later
		if string.sub(QT_PATH, -1) ~= "/" then
			QT_PATH = QT_PATH .. "/"
		end

		flatten( _mocfiles )
		flatten( _qrcfiles )
		flatten( _uifiles )
		flatten( _tsfiles )				

		local QT_MOC_FILES_PATH = sourcePath .. RTM_QT_FILES_PATH_MOC
		local QT_QRC_FILES_PATH = sourcePath .. RTM_QT_FILES_PATH_QRC
		local QT_UI_FILES_PATH	= sourcePath .. RTM_QT_FILES_PATH_UI
		local QT_TS_FILES_PATH	= sourcePath .. RTM_QT_FILES_PATH_TS

		recreateDir( QT_MOC_FILES_PATH )
		recreateDir( QT_QRC_FILES_PATH )
		recreateDir( QT_UI_FILES_PATH )
		recreateDir( QT_TS_FILES_PATH )

		local addedFiles = {}

		-- Set up Qt pre-build steps and add the future generated file paths to the pkg
		for _,file in ipairs( _mocfiles ) do
			local mocFileBase = path.getbasename(file)
			local mocFilePath = path.getabsolute(QT_MOC_FILES_PATH .. "/" .. mocFileBase .. "_moc.cpp")

			local headerSrc = file_read(file);
			if headerSrc:find("Q_OBJECT") then
				prebuildcommands { QT_PREBUILD_LUA_PATH .. ' -moc "' .. path.getabsolute(file) .. '" "' .. QT_PATH .. '" "' .. _projectName .. '" "' .. mocFilePath .. '"' }
				files { file, mocFilePath }
				table.insert(addedFiles, file)
			end
		end

		for _,file in ipairs( _qrcfiles ) do
			local qrcFilePath = path.getabsolute(QT_QRC_FILES_PATH .. "/" .. path.getbasename(file) .. "_qrc.cpp")
			prebuildcommands { QT_PREBUILD_LUA_PATH .. ' -rcc "' .. path.getabsolute(file) .. '" "' .. QT_PATH .. '"' .. " " .. _projectName }
			files { file, qrcFilePath }
			table.insert(addedFiles, qrcFilePath)
		end

		for _,file in ipairs( _uifiles ) do
			local uiFilePath = path.getabsolute(QT_UI_FILES_PATH .. "/" .. path.getbasename(file) .. "_ui.h")
			prebuildcommands { QT_PREBUILD_LUA_PATH .. ' -uic "' .. path.getabsolute(file) .. '" "' .. QT_PATH .. '"' .. " " .. _projectName }
			files { file, uiFilePath }
			table.insert(addedFiles, uiFilePath)
		end

		for _,file in ipairs( _tsfiles ) do
			local tsFilePath = path.getabsolute(QT_TS_FILES_PATH .. "/" .. path.getbasename(file) .. "_ts.qm")
			prebuildcommands { QT_PREBUILD_LUA_PATH .. ' -ts "' .. path.getabsolute(file) .. '" "' .. QT_PATH .. '"' .. " " .. _projectName }
			files { file, tsFilePath }
			table.insert(addedFiles, tsFilePath)
		end				

		local binDir = getBuildDirRoot(_platform, _configuration)
	
		includedirs	{ QT_PATH .. "include" }

		local libsDirectory = QT_PATH .. "lib/"
		if os.is("macosx") then
			linkoptions { "-F " .. libsDirectory }
			includedirs { libsDirectory }
		else
			libdirs { libsDirectory }
		end

		if os.is("windows") then

			_libsToLink = mergeTables(_libsToLink, "WinExtras")
			
			if _copyDynamicLibraries then

				local destPath = binDir
				destPath = string.gsub( destPath, "([/]+)", "\\" ) .. 'bin\\'

				for _, lib in ipairs( _libsToLink ) do
					local libname =  QT_LIB_PREFIX .. lib  .. _dbgPrefix .. '.dll'
					local source = QT_PATH .. 'bin\\' .. libname
					local dest = destPath .. libname
					mkdir(destPath .. "/platforms")
					if not os.isfile(dest) then
						os.copyfile( source, dest )
					end
				end

				otherDLLNames = { "platforms\\qwindows" .. _dbgPrefix, "platforms\\qminimal" .. _dbgPrefix }
				otherDLLSrcPrefix = { "\\plugins\\", "\\plugins\\", "\\bin\\" }
	
				if _ACTION:find("gmake") then
					if _is64bit then
						otherDLLNames = mergeTwoTables(otherDLLNames, {"libstdc++_64-6"})
					else
						otherDLLNames = mergeTwoTables(otherDLLNames, {"libstdc++-6"})
					end
				end
					
				for i=1, #otherDLLNames, 1 do
					local libname =  otherDLLNames[i] .. '.dll'
					local source = QT_PATH .. otherDLLSrcPrefix[i] .. libname
					local dest = destPath .. '\\' .. libname
					if not os.isfile(dest) then
						mkdir(path.getdirectory(dest))
						os.copyfile( source, dest )
					end
				end
			end

			defines { "QT_THREAD_SUPPORT", "QT_USE_QSTRINGBUILDER" }

			includedirs	{ QT_PATH .. "qtwinextras/include" }
				
			if _ACTION:find("vs") then
					-- Qt rcc doesn't support forced header inclusion - preventing us to do PCH in visual studio (gcc accepts files that don't include pch)
					buildoptions( "/FI" .. '"' .. _projectName .. "_pch.h" .. '"' .. " " )
					-- 4127 conditional expression is constant
					-- 4275 non dll-interface class 'stdext::exception' used as base for dll-interface class 'std::bad_cast'
					buildoptions( "/wd4127 /wd4275 /Zc:__cplusplus /std:c++20 /permissive-" ) 
			end

			for _, lib in ipairs( _libsToLink ) do
				local libFile = libsDirectory .. QT_LIB_PREFIX .. lib
				links( libFile .. _dbgPrefix )
			end
	
		elseif os.is("linux") then

			-- check if X11Extras is needed
			local extrasLib = QT_PATH .. "lib/lib" .. QT_LIB_PREFIX .. "X11Extras.a"
			if os.isfile(extrasLib) == true then
				_libsToLink = mergeTables(_libsToLink, "X11Extras")
			end

			-- should run this first (path may vary):
			-- export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/home/user/Qt5.7.0/5.7/gcc_64/lib/pkgconfig
			-- lfs support is required too: sudo luarocks install luafilesystem
			local qtLinks = QT_LIB_PREFIX .. table.concat( _libsToLink, " " .. QT_LIB_PREFIX )

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
				print("Linking framework: " .. libsDirectory .. "Qt" .. lib .. ".framework")
				-- make symbolic link to header files directory
				os.execute("ln -s -f " .. libsDirectory .. "Qt" .. lib .. ".framework/Versions/A/Headers/ " .. QT_PATH .. "include/Qt" .. lib)
				linkoptions {
					"-framework " .. "Qt" .. lib,
				}
			end
		end

	configuration {}
	return addedFiles
end
