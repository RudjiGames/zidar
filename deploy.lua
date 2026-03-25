--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Desc table members
-- 		version
--		shortname
--		longname
--		logosquare
--		logowide

--		@@ARCH@@			armeabi-v7a  mips  x86
--		@@ANDROID_VER@@		_OPTIONS["with-android"]
--		@@VERSION@@			projectGetDescription(_name).version
--		@@SHORT_NAME@@		projectGetDescription(_name).shortname
--		@@LONG_NAME@@		projectGetDescription(_name).longname
--		projectGetDescription(_name).logosquare
--		projectGetDescription(_name).logowide

newoption {
	trigger     = "deploy",
	description = "Include deployment step.",
}

Permissions = {
	AccessNetworkState	= {},
	Internet			= {},
	WriteStorage		= {},
}

local function convertImage(_src, _dst, _width, _height)
	os.mkdir(path.getdirectory(_dst))
	local imageConv = getToolForHost("imageconv")
	os.execute(imageConv .. " " .. _src .. " " .. _dst .. " " .. _width .. " " .. _height)
end

local function cloneDir(_copySrc, _copyDst)
	local srcFiles = os.matchfiles(_copySrc .. "**.*")

	for _,srcFile in ipairs(srcFiles) do
		local fileName		= path.getname(srcFile)
		local srcFileDir	= path.getdirectory(srcFile)
		local srcFileRel	= path.getrelative(_copySrc, srcFileDir)
		local srcPath		= path.join(_copySrc, srcFileRel)
		local srcFileToCopy	= srcPath .. "/" .. fileName

		local dstPath		= path.join(_copyDst, srcFileRel)
		local dstFileToCopy	= dstPath .. "/" .. fileName

		os.mkdir(dstPath)
		if os.isfile(srcFileToCopy) then
			os.copyfile(srcFileToCopy, dstFileToCopy)
		end
	end
end

local function cloneDirWithSed(_copySrc, _copyDst, _sedCmd, _rename)
	local srcFiles = os.matchfiles(_copySrc .. "**.*")

	for _,srcFile in ipairs(srcFiles) do
		local fileName		= path.getname(srcFile)
		local srcFileDir	= path.getdirectory(srcFile)
		local srcFileRel	= path.getrelative(_copySrc, srcFileDir)
		local srcPath		= path.join(_copySrc, srcFileRel)
		local srcFileToCopy	= srcPath .. "/" .. fileName

		local dstPath		= path.join(_copyDst, srcFileRel)
		local dstFileToCopy	= dstPath .. "/" .. fileName

		os.mkdir(dstPath)
		os.execute(_sedCmd .. " " .. srcFileToCopy .. " > " .. dstFileToCopy)
	end
end

local function sedAppendReplace(_str, _search, _replace, _last)
	_last = _last or false
	_replace = string.gsub(_replace, "/", "\\/")
	_str = _str .. "s/" .. _search .. "/" .. _replace .. "/g"
	if _last == false then
		_str = _str .. ';'
	end
	return _str
end

function prepareProjectDeployment(_platform, _configuration, _binDir)
	if  getTargetOS() == "ios"	or
		getTargetOS() == "tvos" then
		prepareDeployment_iOS(_platform, _configuration, _binDir) 	return
	end

	if getTargetOS() == "wasm" then
		prepareDeployment_AsmJS(_platform, _configuration, _binDir)	return
	end
	
	if getTargetOS() == "linux" then
		prepareDeployment_Linux(_platform, _configuration, _binDir)	return
	end

	if getTargetOS() == "osx" then
		prepareDeployment_OSX(_platform, _configuration, _binDir)	return
	end

	if getTargetOS() == "android" then
		prepareDeployment_Android(_platform, _configuration, _binDir)	return
	end

	if  getTargetOS() == "windows"		or
		getTargetOS() == "durango"		or
		getTargetOS() == "winphone8"	or
		getTargetOS() == "winphone81"	or
		getTargetOS() == "winstore81"	or
		getTargetOS() == "winstore82"	then
		prepareDeployment_Windows(_platform, _configuration, _binDir)	return
	end

	--if  getTargetOS() == "switch"		or
	--	getTargetOS() == "swutch2"		then
	--	prepareDeployment_Switch(_platform, _configuration, _binDir)	return
	--end

	return nil
end

imagesConverted = {}

-- Xbox one logo/splash dims
-- 56 x 56
-- 100 x 100
-- 208 x 208
-- 480 x 480
-- 1920 x 1080

local function prepareDeployment_iOS(_platform, _configuration, _binDir)
end

local function prepareDeployment_AsmJS(_platform, _configuration, _binDir)
end

local function prepareDeployment_Linux(_platform, _configuration, _binDir)
end

local function prepareDeployment_OSX(_platform, _configuration, _binDir)
end

local function prepareDeployment_Android(_platform, _configuration, _binDir)
	local copyDst = _binDir .. "/deploy/" .. project().name
	local copySrc = RG_SCRIPTS_DIR .. "/deploy/android/"
	
	local desc = projectGetDescription(project().name)

	local str_arch = "armeabi-v7a"
	if (_OPTIONS["gcc"] == "android-x86") then 
		str_arch = "x86"
	end

	local sedCmd = "sed -e " .. '"'

	sedCmd = sedAppendReplace(sedCmd, "@@BUILD_CONFIGURATION@@",	_configuration)
	sedCmd = sedAppendReplace(sedCmd, "@@ARCH@@",					str_arch)
	sedCmd = sedAppendReplace(sedCmd, "@@ANDROID_VER@@",			androidTarget)
	sedCmd = sedAppendReplace(sedCmd, "@@VERSION@@",				desc.version)
	sedCmd = sedAppendReplace(sedCmd, "@@SHORT_NAME@@",				desc.shortname)
	sedCmd = sedAppendReplace(sedCmd, "@@LONG_NAME@@",				desc.longname, true)

	sedCmd = sedCmd .. '" '

	local destFiles = os.matchfiles(copyDst .. "/**.*")

	cloneDirWithSed(copySrc, copyDst, sedCmd)

	local logoSource = projectGetPath(project().name) .. "/" .. desc.logo_square
	if os.isfile(desc.logo_square) == true then
		logoSource = desc.logo_square
	end

	if imagesConverted[logoSource] ~= true then
		imagesConverted[logoSource] = true
		convertImage(logoSource, copyDst .. "/res/drawable-ldpi/icon.png",		32, 32)
		convertImage(logoSource, copyDst .. "/res/drawable-mdpi/icon.png",		48, 48)
		convertImage(logoSource, copyDst .. "/res/drawable-hdpi/icon.png",		72, 72)
		convertImage(logoSource, copyDst .. "/res/drawable-xhdpi/icon.png",		96, 96)
		convertImage(logoSource, copyDst .. "/res/drawable-xxhdpi/icon.png",	144, 144)
		convertImage(logoSource, copyDst .. "/res/drawable-xxxhdpi/icon.png",	192, 192)
	end

	-- dodati post build command prema filteru
end

local function prepareDeployment_Windows(_platform, _configuration, _binDir)
	local copyDst = RG_LOCATION_PATH .. "/" .. project().name .. "/Image/Loose"
	local copySrc = RG_SCRIPTS_DIR .. "/deploy/durango/"

	if	getTargetOS() == "winphone8"	or
		getTargetOS() == "winphone81"	then
		copySrc = RG_SCRIPTS_DIR .. "/deploy/winphone/"
	end
	
	if	getTargetOS() == "winstore81"	or
		getTargetOS() == "winstore82"	then
		copySrc = RG_SCRIPTS_DIR .. "/deploy/winstore/"
	end
	
	os.mkdir(copyDst)
	
	local desc = projectGetDescription(project().name)
	if desc == nil then return end
	
	desc.shortname = string.gsub(desc.shortname, "_", "")	-- remove invalid character from project names (default if no desc)
	
	local logoSquare	= path.getbasename(desc.logo_square)
	local logoWide		= path.getbasename(desc.logo_wide)
	
	if imagesConverted[desc.logo_wide] ~= true then
		imagesConverted[desc.logo_wide] = true 
		convertImage(desc.logo_wide,   copyDst .. "/" .. logoWide   .. "1920.png",   1920, 1080)
		convertImage(desc.logo_wide,   copyDst .. "/" .. logoWide   .. "620.png",     620,  300)

		local squareLogo = copyDst .. "/" .. logoSquare .. "150.png"

		convertImage(desc.logo_square,	squareLogo,									150,  150)
		convertImage(squareLogo,		copyDst .. "/" .. logoSquare .. "44.png",     44,   44)
		convertImage(squareLogo,		copyDst .. "/" .. logoSquare .. "50.png",     50,   50)
	end
	
	local sedCmd = "sed -e " .. '"'
	
	sedCmd = sedAppendReplace(sedCmd, "@@PUBLISHER_COMPANY@@",	desc.publisher.company)
	sedCmd = sedAppendReplace(sedCmd, "@@PUBLISHER_ORG@@",		desc.publisher.organization)
	sedCmd = sedAppendReplace(sedCmd, "@@PUBLISHER_LOCATION@@",	desc.publisher.location)
	sedCmd = sedAppendReplace(sedCmd, "@@PUBLISHER_STATE@@",	desc.publisher.state)
	sedCmd = sedAppendReplace(sedCmd, "@@PUBLISHER_COUNTRY@@",	desc.publisher.country)
	sedCmd = sedAppendReplace(sedCmd, "@@VERSION@@",			desc.version)
	sedCmd = sedAppendReplace(sedCmd, "@@SHORT_NAME@@",			desc.shortname)
	sedCmd = sedAppendReplace(sedCmd, "@@LONG_NAME@@",			desc.longname)
	sedCmd = sedAppendReplace(sedCmd, "@@LOGO_44@@",			logoSquare .. "44.png")
	sedCmd = sedAppendReplace(sedCmd, "@@LOGO_50@@",			logoSquare .. "50.png")
	sedCmd = sedAppendReplace(sedCmd, "@@LOGO_150@@",			logoSquare .. "150.png")
	sedCmd = sedAppendReplace(sedCmd, "@@LOGO_620@@",			logoWide .. "620.png")
	sedCmd = sedAppendReplace(sedCmd, "@@LOGO_1920@@",			logoWide .. "1920.png")
	sedCmd = sedAppendReplace(sedCmd, "@@DESCRIPTION@@",		desc.description, true)
	
	sedCmd = sedCmd .. '" '
	
	cloneDirWithSed(copySrc, copyDst, sedCmd)
	
	files { copyDst .. "Appxmanifest.xml" }
	files { copyDst .. "Package.appxmanifest" }

end
