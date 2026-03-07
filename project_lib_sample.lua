--
-- Copyright 2025 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--

function addProject_lib_sample(_name, _sampleName)
	
	if _ACTION == nil then return end

	group ("samples")
	project (_name .. "_sample_" ..  _sampleName)

		language	"C++"
		kind		"ConsoleApp"
		uuid		( os.uuid(project().name) )

		local libsPath = getProjectPath(_name, ProjectPath.Root)

		project().path = libsPath .. "/" .. _name .. "/"

		local srcFilesPath = project().path .. "samples/" .. _sampleName .. "/"
		local incFilesPath = srcFilesPath .. "**.h"

		local	sourceFiles = mergeTables(	{ srcFilesPath .. "**.cpp" },
											{ incFilesPath } )
		files  { sourceFiles }

		local withBGFX = false
		local headers = os.matchfiles( incFilesPath )
		for _,file in ipairs( headers ) do
			local headerSrc = file_read(file);
			if headerSrc:find("#define RAPP_WITH_BGFX") then -- NB: a single space character between 'define' and 'RAPP_WITH_BGFX'
				withBGFX = true
				break
			end
		end

		local name = _sampleName
		if string.find(_sampleName, "_") ~= nil then
			name = string.sub(_sampleName, string.find(_sampleName, "_") + 1, string.len(_sampleName))
		end
	
		addPCH( srcFilesPath, name )

		includedirs
		{ 
			project().path .. "samples/",
			incFilesPath,
		}
		
		flags { Flags_Libraries }

		assert(loadfile(RTM_SCRIPTS_DIR .. "configurations.lua"))(	sourceFiles,
																	false,	-- IS_LIBRARY
																	false,	-- IS_SHARED_LIBRARY
																	false,	-- COPY_QT_DLLS
																	false,	-- WITH_QT
																	true	-- EXECUTABLE
																	)


		local dependencies = {}
		if _name ~= "rapp" then
			dependencies = mergeTables(dependencies, { _name })
		end

		if withBGFX then
			dependencies = mergeTables(dependencies, {{"rapp", "bgfx"}})
		else
			dependencies = mergeTables(dependencies, {"rapp"})
		end

		addDependencies(_sampleName, dependencies)
end
