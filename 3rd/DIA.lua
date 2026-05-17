--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Debug Interface Access SDK
-- https://github.com/RudjiGames/DIA

local params	= { ... }
local DIA_ROOT	= params[1]

local DIA_FILES = {
	DIA_ROOT .. "/include/**.h"
}

function projectExtraConfig_DIA()
	includedirs { DIA_ROOT .. "/src" }
	configuration { "gmake" }
		if "mingw-gcc" == _OPTIONS["gcc"] then -- on windows, we patch heap functions, no need to wrap malloc family of funcs
			buildoptions { "-Wno-unknown-pragmas" }
		end
	configuration { "linux-*" }
		buildoptions { "-Wimplicit-fallthrough=0" }
	configuration {}
end

function projectExtraConfigExecutable_DIA()
	if getTargetOS() == "windows" then
		local DIApath = path.getabsolute(path.join(DIA_ROOT, "../"))

		configuration {"windows", "x32", "not gmake" }
			includedirs { DIApath }
			libdirs { DIA_ROOT .. "/lib/x32/" }
			links {"diaguids"}
		configuration {"windows", "x64", "not gmake" }
			includedirs { DIApath }
			libdirs { DIA_ROOT .. "/lib/x64/" }
			links {"diaguids"}
		configuration {}
	end

end

function projectHeaderOnlyLib_DIA()
end

function projectAdd_DIA()
	addProject_3rdParty_lib("DIA", DIA_FILES)
end


function projectSource_DIA()
	return "https://github.com/RudjiGames/DIA"
end
