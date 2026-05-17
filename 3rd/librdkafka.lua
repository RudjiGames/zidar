--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- The Apache Kafka C/C++ library
-- https://github.com/confluentinc/librdkafka/

local params		= { ... }
local KAFKA_ROOT	= params[1]

local ZSTD_INC      = projectGetPath("zstd")

if ZSTD_INC == nil then
	print("ERROR: zstd dependency not found!")
	return
end

local KAFKA_FILES = {
	KAFKA_ROOT .. "/src/**.c",
	KAFKA_ROOT .. "/src/**.h"
}

function projectDependencies_librdkafka()
	return { "openssl", "curl", "zlib", "zstd", "sasl2" }
end 

function projectExtraConfig_librdkafka()
	defines {	"_CRT_SECURE_NO_WARNINGS",
				"LIBRDKAFKA_EXPORTS",
				"STRUCT_IOVEC_DEFINED"
	}
	includedirs {
		KAFKA_ROOT .. "/include",
		KAFKA_ROOT,
		ZSTD_INC   .. "/lib/common"
	}

 	configuration { "vs*", "windows" }
		-- 4133 -  incompatible types - from 'wchar_t [512]' to 'SEC_CHAR *'
		buildoptions { "/wd4133"}
	configuration {}
end

function projectAdd_librdkafka()
	if getTargetOS() ~= "linux" and getTargetOS() ~= "osx" then
		addProject_3rdParty_lib("librdkafka", KAFKA_FILES)
	end
end

function projectSource_librdkafka()
	return "https://github.com/confluentinc/librdkafka/"
end
