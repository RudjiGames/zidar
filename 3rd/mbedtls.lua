--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- An open source, portable, easy to use, readable and flexible TLS library
-- https://github.com/ARMmbed/mbedtls

local params		= { ... }
local MBEDTLS_ROOT	= params[1]

local MBEDTLS_INCLUDE	= {
	MBEDTLS_ROOT .. "/include",
}

local MBEDTLS_FILES = {
	MBEDTLS_ROOT .. "/library/**.c",
}

function projectExtraConfig_mbedtls()
	includedirs { MBEDTLS_INCLUDE }
end

function projectAdd_mbedtls()
	addProject_3rdParty_lib("mbedtls", MBEDTLS_FILES)
end


function projectSource_mbedtls()
	return "https://github.com/ARMmbed/mbedtls"
end
