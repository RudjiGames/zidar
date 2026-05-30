--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

function addProject_lib(_name, _libType, _shared, _suffix, _disablePCH)

	-- A suffixed variant (e.g. "rapp_bgfx") is a second project built from the
	-- same sources as its base project ("rapp") but with a different
	-- configuration. All paths are resolved from the base name; only the
	-- project (and its dependencies/extra-config hooks) use the suffixed name.
	_suffix		= _suffix or ""
	local projectName = _name .. _suffix

	group	( vpathStringFromLibraryType(_libType) )
	project	( projectName )

		_shared		= _shared or false
		_disablePCH	= _disablePCH or false

		project().kind = "StaticLib"
		if _shared then
			project().kind = "SharedLib"
		end

		kind	( project().kind )
		uuid	( os.uuid(project().name) )
		flags	{ Flags_Libraries }

		local projectPath	= projectGetPath(_name)
		local libsPath		= path.getdirectory(projectPath)

		local srcFilesPath	= projectPath .. "/src"
		local incFilesPath	= projectGetIncludePath(projectPath)
		local sourceFiles	= projectSourceFilesWildcard(srcFilesPath, incFilesPath)

		if projectIsCPP(sourceFiles) then
			language	"C++"
		else
			language	"C"
		end			

		files	{ sourceFiles }
	
		local targetOS = getTargetOS()
		if targetOS == "ios" or targetOS == "osx" then
			files	{ srcFilesPath .. "/**.mm" }
		end

		removefiles { projectPath .. "/tests/**.*"   }
		removefiles { projectPath .. "/samples/**.*" }
		removefiles { projectPath .. "/tools/**.*"   }

		includedirs	{
			libsPath, 
			incFilesPath,
			srcFilesPath
		}

		-- no need to cache, done once per project
		if os.isdir(projectPath .. "/3rd") then
			addIncludePath(_name, projectPath .. "/3rd")
		end

		if _disablePCH ~= true then
			addPCH( srcFilesPath, projectName )
		end
		
		projectConfig()
		addDependencies(project().name)
end
