--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- Small, fast, portable implementation of TLS/SSL
-- https://github.com/wolfSSL/wolfssl

local params		= { ... }
local WOLFSSL_ROOT	= params[1]

local WOLFSSL_FILES = {
	WOLFSSL_ROOT .. "/src/crl.c",
	WOLFSSL_ROOT .. "/src/dtls.c",
	WOLFSSL_ROOT .. "/src/dtls13.c",
	WOLFSSL_ROOT .. "/src/internal.c",
	WOLFSSL_ROOT .. "/src/keys.c",
	WOLFSSL_ROOT .. "/src/ocsp.c",
	WOLFSSL_ROOT .. "/src/quic.c",
	WOLFSSL_ROOT .. "/src/sniffer.c",
	WOLFSSL_ROOT .. "/src/ssl.c",
	WOLFSSL_ROOT .. "/src/tls.c",
	WOLFSSL_ROOT .. "/src/tls13.c",
	WOLFSSL_ROOT .. "/src/wolfio.c"
}

local WOLFSSL_DEFINES = { "WOLFSSL_HAVE_MIN", "WOLFSSL_HAVE_MAX" }

function projectExtraConfig_wolfssl()
	includedirs { WOLFSSL_ROOT .. "/wolfssl" }
	defines { WOLFSSL_DEFINES }
end

function projectExtraConfigExecutable_wolfssl()
	includedirs { WOLFSSL_ROOT }
end

function projectAdd_wolfssl()
	addProject_3rdParty_lib("wolfssl", WOLFSSL_FILES)
end

function projectSource_wolfssl()
	return "https://github.com/wolfSSL/wolfssl"
end
