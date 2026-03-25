--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--
-- Based on toolchain.lua from https://github.com/bkaradzic/bx
--

local params = { ... }

dofile(RG_SCRIPTS_DIR .. "/deploy.lua")

local androidTarget    = "24"
local androidPlatform  = "android-" .. androidTarget

newoption {
	trigger = "gcc",
	value = "GCC",
	description = "Choose GCC flavor",
	allowed = {
		{ "android-arm",     	"Android - ARM"              		},
		{ "android-arm64",   	"Android - ARM64"            		},
		{ "android-x86",     	"Android - x86"              		},
		{ "android-x86_64",  	"Android - x86_64"           		},
		{ "wasm2js",         	"Emscripten/Wasm2JS"         		},
		{ "wasm",            	"Emscripten/Wasm"            		},
		{ "freebsd",         	"FreeBSD"                    		},
		{ "linux-gcc",       	"Linux (GCC compiler)"       		},
		{ "linux-gcc-afl",   	"Linux (GCC + AFL fuzzer)"   		},
		{ "linux-clang",     	"Linux (Clang compiler)"     		},
		{ "linux-clang-afl", 	"Linux (Clang + AFL fuzzer)" 		},
		{ "linux-arm-gcc",   	"Linux (ARM, GCC compiler)"  		},
		{ "linux-ppc64le-gcc",  "Linux (PPC64LE, GCC compiler)"		},
		{ "linux-ppc64le-clang","Linux (PPC64LE, Clang compiler)"	},
		{ "linux-riscv64-gcc",  "Linux (RISC-V 64, GCC compiler)"	},
		{ "ios-arm",         	"iOS - ARM"                  		},
		{ "ios-arm64",       	"iOS - ARM64"                		},
		{ "ios-simulator",   	"iOS - Simulator"            		},
		{ "tvos-arm64",      	"tvOS - ARM64"               		},
		{ "xros-arm64",      	"visionOS ARM64"             		},
		{ "xros-simulator",  	"visionOS - Simulator"       		},
		{ "tvos-simulator",  	"tvOS - Simulator"           		},
		{ "mingw-gcc",       	"MinGW"                      		},
		{ "mingw-clang",     	"MinGW (clang compiler)"     		},
		{ "netbsd",          	"NetBSD"                     		},
		{ "osx-x64",         	"OSX - x64"                  		},
		{ "osx-arm64",       	"OSX - ARM64"                		},
		{ "orbis",           	"Orbis"                      		},
		{ "prospero",        	"Prospero"                   		},
		{ "riscv",           	"RISC-V"                     		},
		{ "rpi",             	"RaspberryPi"                		}
    }
}

newoption {
	trigger = "vs",
	value = "toolset",
	description = "Choose VS toolset",
	allowed = {
		{ "vs2017-clang",       "Clang with MS CodeGen"             },
		{ "vs2017-xp",          "Visual Studio 2017 targeting XP"   },
		{ "winstore100",        "Universal Windows App 10.0"        },
		{ "durango",            "Durango"                           },
		{ "orbis",              "Orbis"                             },
		{ "prospero",           "Prospero"                          }
	}
}

newoption {
	trigger = "xcode",
	value = "xcode_target",
	description = "Choose XCode target",
	allowed = {
		{ "osx",  "OSX"      },
		{ "ios",  "iOS"      },
		{ "tvos", "tvOS"     },
		{ "xros", "visionOS" }
	}
}

newoption {
	trigger     = "with-android",
	value       = "#",
	description = "Set Android platform version (default: android-24)."
}

newoption {
	trigger     = "with-ios",
	value       = "#",
	description = "Set iOS target version (default: 13.0)."
}

newoption {
	trigger     = "with-macos",
	value       = "#",
	description = "Set macOS target version (default 13.0)."
}

newoption {
	trigger     = "with-tvos",
	value       = "#",
	description = "Set tvOS target version (default: 13.0)."
}

newoption {
	trigger     = "with-visionos",
	value       = "#",
	description = "Set visionOS target version (default: 1.0)."
}

newoption {
	trigger		= "with-windows",
	value		= "#",
	description = "Set the Windows target platform version (default: $WindowsSDKVersion or 8.1)."
}

newoption {
	trigger     = "with-dynamic-runtime",
	description = "Dynamically link with the runtime rather than statically"
}

newoption {
	trigger     = "with-32bit-compiler",
	description = "Use 32-bit compiler instead 64-bit."
}

newoption {
	trigger     = "with-avx",
	description = "Use AVX extension."
}

newoption {
	trigger     = "with-glfw",
	description = "Links glfw libraries."
}

newoption {
	trigger		= "with-remove-crt",
	description = "Removes CRT library from linking"
}

local androidApiLevel = 24
if _OPTIONS["with-android"] then
	androidApiLevel = _OPTIONS["with-android"]
end

local iosPlatform = ""
if _OPTIONS["with-ios"] then
	iosPlatform = _OPTIONS["with-ios"]
end

local macosPlatform = ""
if _OPTIONS["with-macos"] then
	macosPlatform = _OPTIONS["with-macos"]
end

local tvosPlatform = ""
if _OPTIONS["with-tvos"] then
	tvosPlatform = _OPTIONS["with-tvos"]
end

local xrosPlatform = ""
if _OPTIONS["with-visionos"] then
	xrosPlatform = _OPTIONS["with-visionos"]
end

local windowsPlatform = nil
if _OPTIONS["with-windows"] then
	windowsPlatform = _OPTIONS["with-windows"]
elseif nil ~= os.getenv("WindowsSDKVersion") then
	windowsPlatform = string.gsub(os.getenv("WindowsSDKVersion"), "\\", "")
end

local compiler32bit = false
if _OPTIONS["with-32bit-compiler"] then
	compiler32bit = true
end

local _cachedTargetOS = nil

function getTargetOS()
	if _cachedTargetOS then return _cachedTargetOS end

	local gcc   = _OPTIONS["gcc"]
	local xcode = _OPTIONS["xcode"]
	local vs    = _OPTIONS["vs"]
	local result

	-- gmake - android
	if  gcc == "android-arm"   or gcc == "android-arm64" or
		gcc == "android-x86"   or gcc == "android-x86_64" then
		result = "android"

	-- gmake - wasm2js
	elseif gcc == "wasm2js" or gcc == "wasm" then
		result = "wasm"

	-- gmake - freebsd
	elseif gcc == "freebsd" then
		result = "bsd"

	-- gmake - linux
	elseif	gcc == "linux-gcc"          or gcc == "linux-gcc-afl"       or
			gcc == "linux-clang"        or gcc == "linux-clang-afl"     or
			gcc == "linux-arm-gcc"      or gcc == "linux-ppc64le-gcc"   or
			gcc == "linux-ppc64le-clang"or gcc == "linux-riscv64-gcc" then
		result = "linux"

	-- gmake/xcode - ios
	elseif	xcode == "ios" or gcc == "ios-arm" or gcc == "ios-arm64" or gcc == "ios-simulator" then
		result = "ios"

	-- gmake/xcode - tvos
	elseif	xcode == "tvos" or gcc == "tvos-arm64" or gcc == "tvos-simulator" then
		result = "tvos"

	-- gmake/xcode - xros
	elseif	xcode == "xros" or gcc == "xros-arm64" or gcc == "xros-simulator" then
		result = "xros"

	-- gmake/xcode - osx
	elseif	xcode == "osx" or gcc == "osx-x64" or gcc == "osx-arm64" then
		result = "osx"

	elseif gcc == "rpi"     then result = "rpi"
	elseif gcc == "netbsd"  then result = "netbsd"
	elseif gcc == "riscv"   then result = "riscv"
	elseif gcc == "switch"  then result = "switch"

	elseif vs == "orbis"    or gcc == "orbis"    then result = "orbis"
	elseif vs == "prospero" or gcc == "prospero" then result = "prospero"
	elseif vs == "durango"                       then result = "durango"

	-- we didn't deduce the target OS, assume host
	elseif os.get() == "bsd"     then result = "bsd"
	elseif os.get() == "linux"   then result = "linux"
	elseif os.get() == "macosx"  then result = "osx"
	elseif os.get() == "windows" then result = "windows"
	else
		printErrorAndExit("zidar does not support current host OS " .. os.get())
		return ""
	end

	_cachedTargetOS = result
	return result
end

local function removeCrt()

	defines {
		"RG_NO_CRT=1",
	}

	buildoptions {
		"-nostdlib",
		"-nodefaultlibs",
		"-nostartfiles",
		"-Wa,--noexecstack",
		"-ffreestanding",
	}

	linkoptions {
		"-nostdlib",
		"-nodefaultlibs",
		"-nostartfiles",
		"-Wa,--noexecstack",
		"-ffreestanding",
	}

	configuration { "linux-*" }

		buildoptions {
			"-mpreferred-stack-boundary=4",
			"-mstackrealign",
		}

		linkoptions {
			"-mpreferred-stack-boundary=4",
			"-mstackrealign",
		}

	configuration {}
end

local android = {};

local function androidToolchainRoot()
	if android.toolchainRoot == nil then
		local hostTags = {
			windows = "windows-x86_64",
			linux   = "linux-x86_64",
			macosx  = "darwin-x86_64"
		}
		android.toolchainRoot = "$(ANDROID_NDK_ROOT)/toolchains/llvm/prebuilt/" .. hostTags[os.get()]
	end

	return android.toolchainRoot;
end

RG_ANDROID_TOOLCHAIN_ROOT = androidToolchainRoot()

function isAppleTarget()
	local targetOS = getTargetOS()
	return targetOS == "ios" or targetOS == "tvos" or targetOS == "xros" or targetOS == "osx"
end

local function isWinStoreTarget()
	local targetOS = getTargetOS()
	return targetOS == "winstore81" or targetOS == "winstore82"
end

local _cachedTargetCompiler = nil

function getTargetCompiler()
	if _cachedTargetCompiler then return _cachedTargetCompiler end

	local gcc   = _OPTIONS["gcc"]
	local xcode = _OPTIONS["xcode"]
	local vs    = _OPTIONS["vs"]
	local result

	-- ninja
	if _OPTIONS["cc"] == "gcc" then
		result = "gcc"
	elseif (_ACTION == "ninja") and (_OPTIONS["cc"] == nil) then
		printErrorAndExit("Ninja action must specify target os and compiler\nexample: genie --cc=gcc --os=windows ninja")

	-- gmake - android
	elseif gcc == "android-arm"				then result = "gcc-arm"
	elseif gcc == "android-arm64"			then result = "gcc-arm64"
	elseif gcc == "android-x86"				then result = "gcc-x86"
	elseif gcc == "android-x86_64"			then result = "gcc-x86_64"

	-- gmake - wasm
	elseif gcc == "wasm2js"					then result = "wasm2js"
	elseif gcc == "wasm"					then result = "wasm"

	-- gmake - freebsd
	elseif gcc == "freebsd"					then result = "gcc"

	-- gmake - linux
	elseif gcc == "linux-gcc"				then result = "linux-gcc"
	elseif gcc == "linux-gcc-afl"			then result = "linux-gcc-afl"
	elseif gcc == "linux-clang"				then result = "linux-clang"
	elseif gcc == "linux-clang-afl"			then result = "linux-clang-afl"
	elseif gcc == "linux-arm-gcc"			then result = "linux-arm-gcc"
	elseif gcc == "linux-ppc64le-gcc"		then result = "linux-ppc64le-gcc"
	elseif gcc == "linux-ppc64le-clang"		then result = "linux-ppc64le-clang"
	elseif gcc == "linux-riscv64-gcc"		then result = "linux-riscv64-gcc"

	-- gmake/xcode - ios
	elseif gcc == "ios-arm"					then result = "clang-arm"
	elseif gcc == "ios-arm64"				then result = "clang-arm64"
	elseif gcc == "ios-simulator"			then result = "clang-sim"
	elseif xcode == "ios"					then result = "xcode"

	-- gmake/xcode - tvos
	elseif gcc == "tvos-arm64"				then result = "clang-arm64"
	elseif gcc == "tvos-simulator"			then result = "clang-sim"
	elseif xcode == "tvos"					then result = "xcode"

	-- gmake/xcode - xros
	elseif gcc == "xros-arm64"				then result = "clang-arm64"
	elseif gcc == "xros-simulator"			then result = "clang-sim"
	elseif xcode == "xros"					then result = "xcode"

	-- gmake/xcode - osx
	elseif gcc == "osx-x64"					then result = "clang"
	elseif gcc == "osx-arm64"				then result = "clang"
	elseif xcode == "osx"					then result = "xcode"

	-- gmake - misc
	elseif gcc == "rpi"						then result = "gcc"
	elseif gcc == "switch"					then result = "clang"

	-- gmake/vs - orbis, prospero
	elseif gcc == "orbis"    or vs == "orbis"    then result = "orbis-clang"
	elseif gcc == "prospero" or vs == "prospero" then result = "prospero-clang"

	-- visual studio - durango
	elseif vs == "durango"					then result = _ACTION

	-- visual studio - multi
	elseif vs ~= nil						then result = vs

	-- gmake - mingw
	elseif gcc == "mingw-gcc"				then result = "mingw-gcc"
	elseif gcc == "mingw-clang"				then result = "mingw-clang"

	-- fallback
	elseif actionUsesMSVC()					then result = _ACTION
	elseif actionUsesXcode()				then result = _ACTION
	else
		printErrorAndExit("Target compiler could not be deduced from command line arguments")
		return ""
	end

	_cachedTargetCompiler = result
	return result
end

local g_solutionDir = nil
--- Returns the base directory for the solution, which is RG_ZIDAR_BUILD_DIR/<target-os>/<target-compiler>/<solution-name>/
function getSolutionBaseDir()
	if g_solutionDir then return g_solutionDir end
	local locationDir = getTargetOS() .. "/" .. getTargetCompiler() .. "/" .. solution().name
	g_solutionDir = path.join(RG_ZIDAR_BUILD_DIR, locationDir)
	return g_solutionDir
end

-- Returns the directory where project files are generated, which is RG_ZIDAR_BUILD_DIR/<target-os>/<target-compiler>/<solution-name>/projects/
function getLocationDir()
	return path.join(getSolutionBaseDir(), "projects")
end

function toolchain()

	-- Avoid error when invoking genie --help.
	if (_ACTION == nil) then return false end

	local fullLocation = getLocationDir()

	RG_LOCATION_PATH = fullLocation
	os.mkdir(fullLocation)

	if _ACTION == "clean" then
		os.rmdir(RG_ZIDAR_BUILD_DIR)
	end

	if _OPTIONS["with-android"] then
		androidTarget = _OPTIONS["with-android"]
		androidPlatform = "android-" .. androidTarget
	end

	if _OPTIONS["with-ios"] then
		iosPlatform = _OPTIONS["with-ios"]
	end

	quote = "";
	if os.is("windows") then
		quote = '"'
	end

	if _ACTION == "gmake" then

		if nil == _OPTIONS["gcc"] then
			printErrorAndExit("GCC flavor must be specified!")
		end

		location (path.join(getLocationDir(), _ACTION .. "-" .. _OPTIONS["gcc"]))

		if "android-arm"    == _OPTIONS["gcc"]
		or "android-arm64"  == _OPTIONS["gcc"]
		or "android-x86"    == _OPTIONS["gcc"]
		or "android-x86_64" == _OPTIONS["gcc"] then

			if not os.getenv("ANDROID_NDK_ROOT") then
				printWarning("Please set ANDROID_NDK_ROOT environment variable.")
			end 

			premake.gcc.cc   = RG_ANDROID_TOOLCHAIN_ROOT .. "/bin/clang"
			premake.gcc.cxx  = RG_ANDROID_TOOLCHAIN_ROOT .. "/bin/clang++"
			premake.gcc.ar   = RG_ANDROID_TOOLCHAIN_ROOT .. "/bin/llvm-ar"
			premake.gcc.llvm = true

		elseif "wasm2js" == _OPTIONS["gcc"] or "wasm" == _OPTIONS["gcc"] then

			if not os.getenv("EMSCRIPTEN") then
				printErrorAndExit("Please set EMSCRIPTEN environment variable to point to directory where emcc can be found.")
			end

			premake.gcc.cc   = "\"$(EMSCRIPTEN)/emcc\""
			premake.gcc.cxx  = "\"$(EMSCRIPTEN)/em++\""
			premake.gcc.ar   = "\"$(EMSCRIPTEN)/emar\""
			premake.gcc.llvm = true
			premake.gcc.namestyle = "Emscripten"

		elseif "freebsd" == _OPTIONS["gcc"] then

		elseif "ios-arm"   == _OPTIONS["gcc"] or "ios-arm64" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
			premake.gcc.cxx = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
			premake.gcc.ar  = "ar"

		elseif "xros-arm64"     == _OPTIONS["gcc"] or "xros-simulator" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
			premake.gcc.cxx = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
			premake.gcc.ar  = "ar"

		elseif "ios-simulator" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
			premake.gcc.cxx = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
			premake.gcc.ar  = "ar"

		elseif "tvos-arm64" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
			premake.gcc.cxx = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
			premake.gcc.ar  = "ar"

		elseif "tvos-simulator" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
			premake.gcc.cxx = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
			premake.gcc.ar  = "ar"

		elseif "linux-gcc" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "gcc"
			premake.gcc.cxx = "g++"
			premake.gcc.ar  = "ar"

		elseif "linux-gcc-afl" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "afl-gcc"
			premake.gcc.cxx = "afl-g++"
			premake.gcc.ar  = "ar"

		elseif "linux-clang" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "clang"
			premake.gcc.cxx = "clang++"
			premake.gcc.ar  = "ar"

		elseif "linux-clang-afl" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "afl-clang"
			premake.gcc.cxx = "afl-clang++"
			premake.gcc.ar  = "ar"

		elseif "linux-arm-gcc" == _OPTIONS["gcc"] then

		elseif "linux-ppc64le-gcc" == _OPTIONS["gcc"] then

		elseif "linux-ppc64le-clang" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "clang"
			premake.gcc.cxx = "clang++"
			premake.gcc.ar  = "ar"
			premake.gcc.llvm = true

		elseif "linux-riscv64-gcc" == _OPTIONS["gcc"] then

		elseif "mingw-gcc" == _OPTIONS["gcc"] then

			if not os.getenv("MINGW") then
				print("Set MINGW environment variable.")
			end

			local mingwToolchain = "x86_64-w64-mingw32"
			if compiler32bit then
				if os.is("linux") then
					mingwToolchain = "i686-w64-mingw32"
				else
					mingwToolchain = "mingw32"
				end
			end

			premake.gcc.cc  = "$(MINGW)/bin/" .. mingwToolchain .. "-gcc"
			premake.gcc.cxx = "$(MINGW)/bin/" .. mingwToolchain .. "-g++"
			premake.gcc.ar  = "$(MINGW)/bin/ar"

		elseif "mingw-clang" == _OPTIONS["gcc"] then

			premake.gcc.cc   = "$(CLANG)/bin/clang"
			premake.gcc.cxx  = "$(CLANG)/bin/clang++"
			premake.gcc.ar   = "$(MINGW)/bin/ar"
--			premake.gcc.ar   = "$(CLANG)/bin/llvm-ar"
--			premake.gcc.llvm = true

		elseif "netbsd" == _OPTIONS["gcc"] then

		elseif "osx-x64"   == _OPTIONS["gcc"] or "osx-arm64" == _OPTIONS["gcc"] then

			if os.is("linux") then
				if not os.getenv("OSXCROSS") then
					print("Set OSXCROSS environment variable.")
				end

				local osxToolchain = "x86_64-apple-darwin15-"
				premake.gcc.cc  = "$(OSXCROSS)/target/bin/" .. osxToolchain .. "clang"
				premake.gcc.cxx = "$(OSXCROSS)/target/bin/" .. osxToolchain .. "clang++"
				premake.gcc.ar  = "$(OSXCROSS)/target/bin/" .. osxToolchain .. "ar"
			end

		elseif "orbis" == _OPTIONS["gcc"] then

			if not os.getenv("SCE_ORBIS_SDK_DIR") then
				print("Set SCE_ORBIS_SDK_DIR environment variable.")
			end

			local orbisToolchain = "$(SCE_ORBIS_SDK_DIR)/host_tools/bin/orbis-"

			premake.gcc.cc  = quote .. orbisToolchain .. "clang" .. quote
			premake.gcc.cxx = quote .. orbisToolchain .. "clang++" .. quote
			premake.gcc.ar  = quote .. orbisToolchain .. "ar" .. quote

		elseif "prospero" == _OPTIONS["gcc"] then

			if not os.getenv("SCE_PROSPERO_SDK_DIR") then
				print("Set SCE_PROSPERO_SDK_DIR environment variable.")
			end

			local prosperoToolchain = "$(SCE_PROSPERO_SDK_DIR)/host_tools/bin/prospero-"

			premake.gcc.cc  = quote .. prosperoToolchain .. "clang" .. quote
			premake.gcc.cxx = quote .. prosperoToolchain .. "clang++" .. quote
			premake.gcc.ar  = quote .. prosperoToolchain .. "llvm-ar" .. quote

		elseif "rpi" == _OPTIONS["gcc"] then

		elseif "switch" == _OPTIONS["gcc"] then

			if not os.getenv("NINTENDO_SDK_ROOT") then
				print("Set NINTENDO_SDK_ROOT environment variable.")
			end

			local nintendoToolchain = "\"$(NINTENDO_SDK_ROOT)/Compilers/NX/nx/aarch64/bin/"

			premake.gcc.cc  = nintendoToolchain .. "clang\""
			premake.gcc.cxx = nintendoToolchain .. "clang++\""
			premake.gcc.ar  = nintendoToolchain .. "aarch64-nintendo-nx-elf-ar\""

		elseif "riscv" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "$(FREEDOM_E_SDK)/work/build/riscv-gnu-toolchain/riscv64-unknown-elf/prefix/bin/riscv64-unknown-elf-gcc"
			premake.gcc.cxx = "$(FREEDOM_E_SDK)/work/build/riscv-gnu-toolchain/riscv64-unknown-elf/prefix/bin/riscv64-unknown-elf-g++"
			premake.gcc.ar  = "$(FREEDOM_E_SDK)/work/build/riscv-gnu-toolchain/riscv64-unknown-elf/prefix/bin/riscv64-unknown-elf-ar"
		end -- gcc options
	end -- gmake

	if _ACTION == "vs2022" or _ACTION == "vs2019" or _ACTION == "vs2017" then

		local action = premake.action.current()
		if nil ~= windowsPlatform then
			action.vstudio.windowsTargetPlatformVersion    = windowsPlatform
			action.vstudio.windowsTargetPlatformMinVersion = windowsPlatform
		end
		
		location (path.join(getLocationDir(), _ACTION))
	
		if (_ACTION .. "-clang") == _OPTIONS["vs"] then
			if "vs2017-clang" == _OPTIONS["vs"] then
				premake.vstudio.toolset = "v141_clang_c2"
			else
				premake.vstudio.toolset = ("LLVM-" .. _ACTION)
			end
			location (path.join(RG_ZIDAR_BUILD_DIR, "projects", _ACTION .. "-clang"))
		elseif "winstore100" == _OPTIONS["vs"] then
			premake.vstudio.toolset = "v141"
			premake.vstudio.storeapp = "10.0"
			platforms { "ARM" }
			location (path.join(RG_ZIDAR_BUILD_DIR, "projects", _ACTION .. "-winstore100"))
		elseif "durango" == _OPTIONS["vs"] then
			if not os.getenv("DurangoXDK") then
				print("DurangoXDK not found.")
			end
			premake.vstudio.toolset = "v140"
			premake.vstudio.storeapp = "durango"
			platforms { "Durango" }
			location (path.join(RG_ZIDAR_BUILD_DIR, "projects", _ACTION .. "-durango"))
		elseif "orbis" == _OPTIONS["vs"] then
			if not os.getenv("SCE_ORBIS_SDK_DIR") then
				print("Set SCE_ORBIS_SDK_DIR environment variable.")
			end
			platforms { "Orbis" }
			location (path.join(RG_ZIDAR_BUILD_DIR, "projects", _ACTION .. "-orbis"))
		elseif "prospero" == _OPTIONS["vs"] then
			if not os.getenv("SCE_PROSPERO_SDK_DIR") then
				print("Set SCE_PROSPERO_SDK_DIR environment variable.")
			end
			platforms { "Prospero" }
			location (path.join(RG_ZIDAR_BUILD_DIR, "projects", _ACTION .. "-prospero"))
		end

	elseif _ACTION and _ACTION:match("^xcode.+$") then
		local action = premake.action.current()

		local str_or = function(str, def)
			return #str > 0 and str or def
		end

		if "osx" == _OPTIONS["xcode"] then
			action.xcode.macOSTargetPlatformVersion = str_or(macosPlatform, "13.0")
			premake.xcode.toolset = "macosx"
			location (path.join(getLocationDir(), _ACTION .. "-osx"))

		elseif "ios" == _OPTIONS["xcode"] then
			action.xcode.iOSTargetPlatformVersion = str_or(iosPlatform, "13.0")
			premake.xcode.toolset = "iphoneos"
			location (path.join(getLocationDir(), _ACTION .. "-ios"))

		elseif "tvos" == _OPTIONS["xcode"] then
			action.xcode.tvOSTargetPlatformVersion = str_or(tvosPlatform, "13.0")
			premake.xcode.toolset = "appletvos"
			location (path.join(getLocationDir(), _ACTION .. "-tvos"))

		elseif "xros" == _OPTIONS["xcode"] then
			action.xcode.visionOSTargetPlatformVersion = str_or(xrosPlatform, "1.0")
			premake.xcode.toolset = "xros"
			location (path.join(getLocationDir(), _ACTION .. "-xros"))
		end
	end

	if not _OPTIONS["with-dynamic-runtime"] then
		flags { "StaticRuntime" }
	end

	if _OPTIONS["with-avx"] then
		flags { "EnableAVX" }
	end

	if (_OPTIONS["with-remove-crt"] ~= nil) then
		removeCrt()
	end

	configuration {} -- reset configuration

	return true
end

function getBuildDirRoot(_platform, _configuration)
	return getSolutionBaseDir() .. "/" .. _platform .. "/" .. _configuration
end

function commonConfig(_platform, _configuration)

	local isExecutable = project().kind == "ConsoleApp" or project().kind == "WindowedApp"
	
	local buildRoot = getBuildDirRoot(_platform, _configuration)
	local binDir = buildRoot .. "/bin"
	local libDir = buildRoot .. "/lib"
	local objDir = buildRoot .. "/obj/" .. project().name

	os.mkdir(binDir)
	os.mkdir(libDir)
	os.mkdir(objDir)

	if project().kind == "StaticLib" then
		binDir = libDir
	end

	configuration {_platform, _configuration}
		targetdir (binDir)
		objdir (objDir)
		libdirs {libDir}
		debugdir (binDir)

	defines {
		"__STDC_LIMIT_MACROS",
		"__STDC_FORMAT_MACROS",
		"__STDC_CONSTANT_MACROS",
	}

	flags {
		"Cpp20",
		"ExtraWarnings",
		"FloatFast",
	}

	configuration { "vs*", "not orbis", "not prospero", _platform, _configuration }
		includedirs { RG_CORE_COMPAT_DIR .. "/msvc" }
		defines {
			"NOMINMAX",
			"WIN32",
			"_WIN32",
			"_HAS_EXCEPTIONS=0",
			"_HAS_ITERATOR_DEBUGGING=0",
			"_SCL_SECURE=0",
			"_SECURE_SCL=0",
			"_SCL_SECURE_NO_WARNINGS",
			"_CRT_SECURE_NO_WARNINGS",
			"_CRT_SECURE_NO_DEPRECATE",
			"_WINSOCK_DEPRECATED_NO_WARNINGS",
		}
		buildoptions {
			"/Zc:preprocessor",
			"/Zc:__cplusplus",
			"/std:c++20",
			"/Ob2"		-- The Inline Function Expansion
		}
		linkoptions {
			"/ignore:4221", -- LNK4221: This object file does not define any previously undefined public symbols, so it will not be used by any link operation that consumes this library
		}

	configuration { "linux*", _platform, _configuration }
		defines { "RG_LINUX" }

	configuration { "vs*", "not NX32", "not NX64", _platform, _configuration }
		flags {	"EnableAVX" }

	configuration { "vs2008", _platform, _configuration }
		includedirs { RG_CORE_COMPAT_DIR .. "/msvc/pre1600" }

	configuration { "x32", "vs*", "not orbis", "not prospero", _platform, _configuration }
		defines { "RG_WIN32", "RG_WINDOWS" }

	configuration { "x64", "vs*", "not orbis", "not prospero", _platform, _configuration }
		defines { "RG_WIN64", "RG_WINDOWS", "_WIN64" }

	configuration { "ARM", "vs*", "not orbis", "not prospero", _platform, _configuration }

	configuration { "vs*-clang", _platform, _configuration }
		buildoptions {
			"-Qunused-arguments",
		}

	configuration { "x32", "vs*-clang", _platform, _configuration }
		defines { "RG_WIN32", "RG_WINDOWS" }

	configuration { "x64", "vs*-clang", _platform, _configuration }
		defines { "RG_WIN64", "RG_WINDOWS" }

	configuration { "winstore*", _platform, _configuration }
		removeflags {
			"StaticRuntime",
			"NoBufferSecurityCheck",
		}
		buildoptions {
			"/wd4530", -- vccorlib.h(1345): warning C4530: C++ exception handler used, but unwind semantics are not enabled. Specify /EHsc
		}
		linkoptions {
			"/ignore:4264" -- LNK4264: archiving object file compiled with /ZW into a static library; note that when authoring Windows Runtime types it is not recommended to link with a static library that contains Windows Runtime metadata
		}

	configuration { "*-gcc* or osx", _platform, _configuration }
		buildoptions {
			"-Wshadow",
			"-Wundef",
		}

	configuration { "mingw-*", _platform, _configuration }
		defines { "WIN32" }
		includedirs { RG_CORE_COMPAT_DIR .. "/mingw" }

		defines {
			"MINGW_HAS_SECURE_API=1",
		}
		buildoptions {
			"-Wunused-value",
			"-fdata-sections",
			"-ffunction-sections",
			"-msse4.2",
			"-Wundef",
		}
		linkoptions {
			"-Wl,--gc-sections",
			"-static",
			"-static-libgcc",
			"-static-libstdc++",
		}
		if isExecutable then
		links { 
			"ole32",
			"oleaut32",
			"uuid",
			"gdi32"
		}
		end

	configuration { "linux-*", _platform, _configuration }
		if isExecutable then
		links {
			"pthread",
		}
		end

	configuration { "osx-*", _platform, _configuration }
		if isExecutable then
		linkoptions {
			"-framework Foundation",
			"-framework IOKit",
			"-framework AppKit",
			"-framework QuartzCore",
			"-framework Metal"
		}
		end

	configuration { "x32", "mingw-gcc", _platform, _configuration }
		defines { "RG_WIN32", "RG_WINDOWS", "WINVER=0x0601", "_WIN32_WINNT=0x0601" }
		buildoptions { "-m32" }
		libdirs {
			"$(MINGW)/x86_64-w64-mingw32/lib32"
		}

	configuration { "x64", "mingw-gcc", _platform, _configuration }
		defines { "RG_WIN64", "RG_WINDOWS", "WINVER=0x0601", "_WIN32_WINNT=0x0601" }
		libdirs {
			"$(GLES_X64_DIR)",
			"$(MINGW)/x86_64-w64-mingw32/lib"
		}
		buildoptions { "-m64" }

	configuration { "mingw-clang", _platform, _configuration }
		buildoptions {
			"-isystem $(MINGW)/lib/gcc/x86_64-w64-mingw32/4.8.1/include/c++",
			"-isystem $(MINGW)/lib/gcc/x86_64-w64-mingw32/4.8.1/include/c++/x86_64-w64-mingw32",
			"-isystem $(MINGW)/x86_64-w64-mingw32/include",
		}
		linkoptions {
			"-Qunused-arguments",
			"-Wno-error=unused-command-line-argument-hard-error-in-future",
		}

	configuration { "x32", "mingw-clang", _platform, _configuration }
		defines { "RG_WIN32", "RG_WINDOWS", "WINVER=0x0601", "_WIN32_WINNT=0x0601" }
		buildoptions { "-m32" }

	configuration { "x64", "mingw-clang", _platform, _configuration }
		defines { "RG_WIN64", "RG_WINDOWS", "WINVER=0x0601", "_WIN32_WINNT=0x0601" }
		libdirs {
			"$(GLES_X64_DIR)",
		}
		buildoptions { "-m64" }

	configuration { "linux-clang", _platform, _configuration }
		buildoptions {
			"-stdlib=libc++",
		}
		links {
			"c++",
		}

	configuration { "linux-g*", _platform, _configuration }
		buildoptions {
			"-mfpmath=sse", -- force SSE to get 32-bit and 64-bit builds deterministic.
		}

	configuration { "linux-gcc* or linux-clang*", _platform, _configuration }
		buildoptions {
			"-msse4.2",
			"-Wshadow",
			"-Wunused-value",
			"-Wundef"
		}
		links {
			"rt",
			"dl",
		} 
		linkoptions {
			"-Wl,--gc-sections",
			"-Wl,--as-needed",
		}

	configuration { "linux-*", "x32", _platform, _configuration }
		buildoptions {
			"-m32",
		}

	configuration { "linux-*", "x64", _platform, _configuration }
		buildoptions {
			"-m64",
		}

	configuration { "linux-arm-gcc", _platform, _configuration }
		buildoptions {
			"-Wunused-value",
			"-Wundef",
		}
		links {
			"rt",
			"dl",
		}
		linkoptions {
			"-Wl,--gc-sections",
		}

	configuration { "android-*", "debug", _platform, _configuration }
		defines { "NDK_DEBUG=1" }

	configuration { "android-*", _platform, _configuration }
		defines { "RG_ANDROID" }
		targetprefix ("lib")
		flags {
			"NoImportLib",
		}
		links {
			"c",
			"dl",
			"m",
			"android",
			"log",
			"c++_shared",
		}
		buildoptions {
			"--gcc-toolchain=" .. RG_ANDROID_TOOLCHAIN_ROOT,
			"--sysroot=" .. RG_ANDROID_TOOLCHAIN_ROOT .. "/sysroot",
			"-DANDROID",
			"-fPIC",
			"-no-canonical-prefixes",
			"-Wa,--noexecstack",
			"-fstack-protector-strong",
			"-ffunction-sections",
			"-Wunused-value",
			"-Wundef",
		}
		linkoptions {
			"--gcc-toolchain=" .. RG_ANDROID_TOOLCHAIN_ROOT,
			"--sysroot=" .. RG_ANDROID_TOOLCHAIN_ROOT .. "/sysroot",
			"-no-canonical-prefixes",
			"-Wl,--no-undefined",
			"-Wl,-z,noexecstack",
			"-Wl,-z,relro",
			"-Wl,-z,now",
		}
		if isExecutable then
		buildoptions {
			"-Wa,--noexecstack"
		}
		linkoptions {
			"-Wl,-z,noexecstack" 
		}
		end

	configuration { "android-arm", _platform, _configuration }
		buildoptions {
			"--target=armv7-none-linux-android" .. androidApiLevel,
			"-mthumb",
			"-march=armv7-a",
			"-mfloat-abi=softfp",
			"-mfpu=neon",
		}
		linkoptions {
			"--target=armv7-none-linux-android" .. androidApiLevel,
			"-march=armv7-a",
		}

	configuration { "android-arm64", _platform, _configuration }
		buildoptions {
			"--target=aarch64-none-linux-android" .. androidApiLevel,
		}
		linkoptions {
			"--target=aarch64-none-linux-android" .. androidApiLevel,
		}

	configuration { "android-x86", _platform, _configuration }
		buildoptions {
			"--target=i686-none-linux-android" .. androidApiLevel,
			"-mtune=atom",
			"-mstackrealign",
			"-msse4.2",
			"-mfpmath=sse",
		}
		linkoptions {
			"--target=i686-none-linux-android" .. androidApiLevel,
		}

	configuration { "android-x86_64", _platform, _configuration }
		buildoptions {
			"--target=x86_64-none-linux-android" .. androidApiLevel,
		}
		linkoptions {
			"--target=x86_64-none-linux-android" .. androidApiLevel,
		}
		
	configuration { "wasm2js or wasm", _platform, _configuration }
		defines { "RG_ASMJS" }
		buildoptions {
			"-Wunused-value",
			"-Wundef"
		}
		linkoptions {
			"-s MAX_WEBGL_VERSION=2",
			"-s TOTAL_MEMORY=64MB",
			"-s ALLOW_MEMORY_GROWTH=1",
			"-s MALLOC=emmalloc",
			"-s WASM=0",
		}
		flags {
			"Optimize"
		}

	configuration { "linux-ppc64le*", _platform, _configuration }
		buildoptions {
			"-fsigned-char",
			"-Wunused-value",
			"-Wundef",
			"-mcpu=power8",
		}
		links {
			"rt",
			"dl",
		}
		linkoptions {
			"-Wl,--gc-sections",
		}

	configuration { "linux-riscv64*", _platform, _configuration }
		buildoptions {
			"-Wunused-value",
			"-Wundef",
			"-march=rv64g"
		}
		links {
			"rt",
			"dl",
		}
		linkoptions {
			"-Wl,--gc-sections",
		}

	configuration { "freebsd", _platform, _configuration }
		defines { "RG_FREEBSD" }
		includedirs { RG_CORE_COMPAT_DIR .. "/freebsd" }

	configuration { "durango", _platform, _configuration }
		includedirs { RG_CORE_COMPAT_DIR .. "/msvc"	}
		removeflags { 
			"StaticRuntime", 
			"NoExceptions" 
		}
		buildoptions { "/EHsc /await /std:c++latest" }
		linkoptions { "/ignore:4264" }


	configuration { "Xbox360", _platform, _configuration }
		defines { "RG_XBOX360" }
		includedirs { RG_CORE_COMPAT_DIR .. "/msvc" }
		defines {
			"NOMINMAX",
			"_XBOX",
		}

	configuration { "osx-x64", _platform, _configuration }
		defines { "RG_OSX" }
		linkoptions {
			"-arch x86_64",
		}
		buildoptions {
			"-arch x86_64",
			"-msse4.2",
			"-target x86_64-apple-macos" .. (#macosPlatform > 0 and macosPlatform or "13.0"),
		}

	configuration { "osx-arm64", _platform, _configuration }
		defines { "RG_OSX" }
		linkoptions {
			"-arch arm64",
		}
		buildoptions {
			"-arch arm64",
			"-Wno-error=unused-command-line-argument",
			"-Wno-unused-command-line-argument",
		}
	
	configuration { "osx*", _platform, _configuration }
		buildoptions {
			"-Wfatal-errors",
			"-Wunused-value",
			"-Wundef",
		}
		includedirs { RG_CORE_COMPAT_DIR .. "/osx" }

	configuration { "ios*", _platform, _configuration }
		defines { "RG_IOS" }
		linkoptions {
			"-lc++",
		}
		buildoptions {
			"-Wfatal-errors",
			"-Wunused-value",
			"-Wundef",
		}
		includedirs { RG_CORE_COMPAT_DIR .. "/ios" }

	configuration { "ios-arm", _platform, _configuration }
		linkoptions {
			"-arch armv7",
		}
		buildoptions {
			"-arch armv7",
		}

	configuration { "ios-arm64", _platform, _configuration }
		linkoptions {
			"-arch arm64",
		}
		buildoptions {
			"-arch arm64",
		}

	configuration { "ios-arm*", _platform, _configuration }
		linkoptions {
			"--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS" ..iosPlatform .. ".sdk",
			"-L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS" ..iosPlatform .. ".sdk/usr/lib/system",
			"-F/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS" ..iosPlatform .. ".sdk/System/Library/Frameworks",
			"-F/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS" ..iosPlatform .. ".sdk/System/Library/PrivateFrameworks",
		}
		buildoptions {
			"--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS" ..iosPlatform .. ".sdk",
			"-fembed-bitcode",
		}

	configuration { "xros*", _platform, _configuration }
		defines { "RG_XROS" }
		linkoptions {
			"-lc++",
		}
		buildoptions {
			"-Wfatal-errors",
			"-Wunused-value",
			"-Wundef",
		}
		includedirs { RG_CORE_COMPAT_DIR .. "/ios" }

	configuration { "xros-arm64", _platform, _configuration }
		linkoptions {
			"--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/XROS.platform/Developer/SDKs/XROS" ..xrosPlatform.. ".sdk",
			"-L/Applications/Xcode.app/Contents/Developer/Platforms/XROS.platform/Developer/SDKs/XROS" ..xrosPlatform .. ".sdk/usr/lib/system",
			"-F/Applications/Xcode.app/Contents/Developer/Platforms/XROS.platform/Developer/SDKs/XROS" ..xrosPlatform .. ".sdk/System/Library/Frameworks",
			"-F/Applications/Xcode.app/Contents/Developer/Platforms/XROS.platform/Developer/SDKs/XROS" ..xrosPlatform .. ".sdk/System/Library/PrivateFrameworks",
		}
		buildoptions {
			"--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/XROS.platform/Developer/SDKs/XROS" ..xrosPlatform .. ".sdk",
		}

	configuration { "xros-simulator", _platform, _configuration }
		linkoptions {
			"--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/XRSimulator.platform/Developer/SDKs/XRSimulator" ..xrosPlatform.. ".sdk",
			"-L/Applications/Xcode.app/Contents/Developer/Platforms/XRSimulator.platform/Developer/SDKs/XRSimulator" ..xrosPlatform .. ".sdk/usr/lib/system",
			"-F/Applications/Xcode.app/Contents/Developer/Platforms/XRSimulator.platform/Developer/SDKs/XRSimulator" ..xrosPlatform .. ".sdk/System/Library/Frameworks",
		}
		buildoptions {
			"--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/XRSimulator.platform/Developer/SDKs/XRSimulator" ..xrosPlatform .. ".sdk",
		}

	configuration { "ios-simulator", _platform, _configuration }
		linkoptions {
			"--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator" ..iosPlatform .. ".sdk",
			"-L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator" ..iosPlatform .. ".sdk/usr/lib/system",
			"-F/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator" ..iosPlatform .. ".sdk/System/Library/Frameworks",
			"-F/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator" ..iosPlatform .. ".sdk/System/Library/PrivateFrameworks",
		}
		buildoptions {
			"--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator" ..iosPlatform .. ".sdk",
		}

	configuration { "tvos*", _platform, _configuration }
		defines { "RG_TVOS" }
		linkoptions {
			"-lc++",
		}
		buildoptions {
			"-Wfatal-errors",
			"-Wunused-value",
			"-Wundef",
		}
		includedirs { RG_CORE_COMPAT_DIR .. "/ios" }

	configuration { "tvos-arm64", _platform, _configuration }
		linkoptions {
			"-mtvos-version-min=9.0",
			"-arch arm64",
			"--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS" ..tvosPlatform .. ".sdk",
			"-L/Applications/Xcode.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS" ..tvosPlatform .. ".sdk/usr/lib/system",
			"-F/Applications/Xcode.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS" ..tvosPlatform .. ".sdk/System/Library/Frameworks",
			"-F/Applications/Xcode.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS" ..tvosPlatform .. ".sdk/System/Library/PrivateFrameworks",
		}
		buildoptions {
			"-mtvos-version-min=9.0",
			"-arch arm64",
			"--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS" ..tvosPlatform .. ".sdk",
		}

	configuration { "tvos-simulator", _platform, _configuration }
		linkoptions {
			"--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/AppleTVSimulator.platform/Developer/SDKs/AppleTVSimulator" ..tvosPlatform .. ".sdk",
			"-L/Applications/Xcode.app/Contents/Developer/Platforms/AppleTVSimulator.platform/Developer/SDKs/AppleTVSimulator" ..tvosPlatform .. ".sdk/usr/lib/system",
			"-F/Applications/Xcode.app/Contents/Developer/Platforms/AppleTVSimulator.platform/Developer/SDKs/AppleTVSimulator" ..tvosPlatform .. ".sdk/System/Library/Frameworks",
			"-F/Applications/Xcode.app/Contents/Developer/Platforms/AppleTVSimulator.platform/Developer/SDKs/AppleTVSimulator" ..tvosPlatform .. ".sdk/System/Library/PrivateFrameworks",
		}
		buildoptions {
			"--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/AppleTVSimulator.platform/Developer/SDKs/AppleTVSimulator" ..tvosPlatform .. ".sdk",
		}

	configuration { "orbis", _platform, _configuration }
		defines { "RG_ORBIS" }
		includedirs {
			RG_CORE_COMPAT_DIR .. "/freebsd",
			"$(SCE_ORBIS_SDK_DIR)/target/include",
			"$(SCE_ORBIS_SDK_DIR)/target/include_common",
		}
		links {
			"ScePosix_stub_weak",
			"ScePad_stub_weak",
			"SceMouse_stub_weak",
			"SceSysmodule_stub_weak",
			"SceUserService_stub_weak",
			"SceIme_stub_weak"
		}
	configuration { "prospero", _platform, _configuration }
		defines { "RG_PROSPERO" }
		includedirs {
			RG_CORE_COMPAT_DIR .. "/freebsd",
			"$(SCE_PROSPERO_SDK_DIR)/target/include",
			"$(SCE_PROSPERO_SDK_DIR)/target/include_common",
		}
		links {
			"ScePosix_stub_weak",
			"ScePad_stub_weak",
			"SceMouse_stub_weak",
			"SceSysmodule_stub_weak",
			"SceUserService_stub_weak",
			"SceIme_stub_weak"
		}

	configuration { "rpi", _platform, _configuration }
		defines { "RG_RPI" }
		libdirs {
			path.join(RG_ZIDAR_BUILD_DIR, "lib/rpi"),
			"/opt/vc/lib",
		}
		defines {
			"__VCCOREVER__=0x04000000", -- There is no special prefedined compiler symbol to detect RaspberryPi, faking it.
			"__STDC_VERSION__=199901L",
		}
		buildoptions {
			"-Wunused-value",
			"-Wundef",
		}
		includedirs {
			"/opt/vc/include",
			"/opt/vc/include/interface/vcos/pthreads",
			"/opt/vc/include/interface/vmcs_host/linux",
		}
		links {
			"rt",
			"dl",
		}
		linkoptions {
			"-Wl,--gc-sections",
		}

	configuration { "riscv", _platform, _configuration }
		targetdir (path.join(RG_ZIDAR_BUILD_DIR, "riscv/bin"))
		objdir (path.join(RG_ZIDAR_BUILD_DIR, "riscv/obj"))
		defines {
			"RG_RISCV",
			"__BSD_VISIBLE",
			"__MISC_VISIBLE",
		}
		includedirs {
			"$(FREEDOM_E_SDK)/work/build/riscv-gnu-toolchain/riscv64-unknown-elf/prefix/riscv64-unknown-elf/include",
			RG_CORE_COMPAT_DIR .. "/riscv",
		}
		buildoptions {
			"-Wunused-value",
			"-Wundef",
			"--sysroot=$(FREEDOM_E_SDK)/work/build/riscv-gnu-toolchain/riscv64-unknown-elf/prefix/riscv64-unknown-elf",
		}

	configuration { "durango", _platform, _configuration }
		defines { "RG_DURANGO", "NOMINMAX" }
		links {
			"d3d11_x",
			"d3d12_x",
			"combase",
			"kernelx"
		}

	configuration { "switch", _platform, _configuration }
		defines { "RG_SWITCH" }
		links {
			"c",
			"c++",
			"nnSdk",
			"nn_init_memory",
			"nn_profiler",
		}
		if os.getenv("NINTENDO_SDK_ROOT") then
		libdirs {
			os.getenv("NINTENDO_SDK_ROOT") .. "/Compilers/NX/nx/aarch64/lib/aarch64-nintendo-nx-elf-ropjop/noeh/",
			os.getenv("NINTENDO_SDK_ROOT") .. "/Compilers/NX/nx/aarch64/lib/aarch64-nintendo-nx-elf-ropjop/",
			os.getenv("NINTENDO_SDK_ROOT") .. "/Libraries/NX-NXFP2-a64/Release/",
		}
		includedirs {
			os.getenv("NINTENDO_SDK_ROOT") .. "/Include/",
			os.getenv("NINTENDO_SDK_ROOT") .. "/Common/Configs/Targets/NX-NXFP2-a64/Include"
		}
		end
	configuration { "switch", "debug", _platform, _configuration }
		defines { "NN_SDK_BUILD_DEBUG" }
	configuration { "switch", "release", _platform, _configuration }
		defines { "NN_SDK_BUILD_DEVELOP" }
	configuration { "switch", "retail", _platform, _configuration }
		defines { "NN_SDK_BUILD_RELEASE" }

	if isExecutable then
		configuration { "mingw-clang", _platform, _configuration }
			kind "ConsoleApp"

		configuration { "wasm2js or wasm", _platform, _configuration }
			kind "ConsoleApp"
			targetextension ".html"

		configuration { "mingw*", _platform, _configuration }
			targetextension ".exe"

		configuration { "orbis", _platform, _configuration }
			targetextension ".elf"

		configuration { "prospero", _platform, _configuration }
			targetextension ".self"

		configuration { "android*", _platform, _configuration }
			kind "ConsoleApp"
			targetextension ".so"
	end

	configuration {}

	if _OPTIONS["deploy"] ~= nil and isExecutable then
		prepareProjectDeployment(_platform, _configuration, binDir)
	end
end

local function strip()

	configuration { "android-*", "Release or Retail" }
		postbuildcommands {
			"$(SILENT) echo Stripping symbols.",
			"$(SILENT) " .. RG_ANDROID_TOOLCHAIN_ROOT .. "/bin/llvm-strip -s \"$(TARGET)\""
		}

	configuration { "linux-* or rpi", "Release or Retail" }
		postbuildcommands {
			"$(SILENT) echo Stripping symbols.",
			"$(SILENT) strip -s \"$(TARGET)\""
		}

	configuration { "mingw*", "Release or Retail" }
		postbuildcommands {
			"$(SILENT) echo Stripping symbols.",
			"$(SILENT) $(MINGW)/bin/strip -s \"$(TARGET)\""
		}

	configuration { "riscv", "Release or Retail" }
		postbuildcommands {
			"$(SILENT) echo Stripping symbols.",
			"$(SILENT) $(FREEDOM_E_SDK)/work/build/riscv-gnu-toolchain/riscv64-unknown-elf/prefix/bin/riscv64-unknown-elf-strip -s \"$(TARGET)\""
		}

	configuration { "wasm2js or wasm" }
		postbuildcommands {
			"$(SILENT) echo Running wasm2js finalize.",
			"$(SILENT) $(EMSCRIPTEN)/emcc -O2 -s TOTAL_MEMORY=268435456 \"$(TARGET)\" -o \"$(TARGET)\".html"
			-- ALLOW_MEMORY_GROWTH
		}

	configuration {} -- reset configuration
end

--function actionTargetsWASM()
--	return (_OPTIONS["gcc"] == "wasm") or (_OPTIONS["gcc"] == "wasm2js")
--end

-- has to be called from an active solution
function setPlatforms()
	if actionUsesXcode() then --actionTargetsWASM() then
		configurations { "release" }
		platforms { "Universal" }
	elseif actionUsesMSVC() then
		local targetOS = getTargetOS()
		if  not (targetOS == "durango")	and 
			not (targetOS == "orbis")		and
			not (targetOS == "prospero")	and
			not (targetOS == "winstore81")	and
			not (targetOS == "winstore82") 
			then -- these platforms set their own platform config
			configurations { "debug", "release", "retail" }
			platforms { "x32", "x64" }
		end
	else
		configurations { "debug", "release", "retail" }
		platforms { "x32", "x64", "native" }
	end

	if not toolchain() then
		return -- no action specified
	end 
end
