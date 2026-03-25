--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- LibDOM - an implementation of the W3C DOM
-- https://github.com/netsurf-plan9/libdom.git

local params		= { ... }
local LIBPU_ROOT	= params[1]

local LIBPU_FILES = {
	LIBPU_ROOT .. "/src/**.c",
	LIBPU_ROOT .. "/src/**.h",
}

function projectExtraConfig_libparserutils()
	defines { "WITHOUT_ICONV_FILTER" }
	includedirs { LIBPU_ROOT .. "/Include" }
	includedirs { LIBPU_ROOT .. "/src" }
end

function projectAdd_libparserutils()
	local cwd = _WORKING_DIR
	os.chdir(LIBPU_ROOT)
	os.execute("perl build/make-aliases.pl")
	os.chdir(cwd)

	addProject_3rdParty_lib("libparserutils", LIBPU_FILES)
end

function projectSource_libparserutils()
	return "https://github.com/netsurf-plan9/libdom.git"
end
