--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- TLS/SSL and crypto library
-- https://github.com/openssl/openssl.git

local params		= { ... }
local OSSL_ROOT		= params[1]

function projectExtraConfigExecutable_openssl()
	if getTargetOS() == "windows" then
		configuration {"x64"}
			includedirs { OSSL_ROOT .. "/x64/include" }
			libdirs { OSSL_ROOT .. "/x64/lib" }
			links   {
				"libcrypto",
				"libssl"
			}
		configuration {"x32"}
			includedirs { OSSL_ROOT .. "/x86/include" }
			libdirs { OSSL_ROOT .. "/x86/lib" }
			links   {
				"libcrypto",
				"libssl"
			}
	end
end

function projectSource_openssl()
	return "https://github.com/openssl/openssl.git"
end
