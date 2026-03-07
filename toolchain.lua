--
-- Copyright 2025 Milos Tosic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--
-- Based on toolchain.lua from https://github.com/bkaradzic/bx
--

local params = { ... }
local EXECUTABLE	= params[1]
local IS_3RD_PARTY	= params[2]

dofile(RTM_SCRIPTS_DIR .. "deploy.lua")

androidTarget    = "24"
androidPlatform  = "android-" .. androidTarget

newoption {
	trigger = "gcc",
	value = "GCC",
	description = "Choose GCC flavor",
	allowed = {
		{ "android-arm",     "Android - ARM"              },
		{ "android-arm64",   "Android - ARM64"            },
		{ "android-x86",     "Android - x86"              },
		{ "android-x86_64",  "Android - x86_64"           },
		{ "wasm2js",         "Emscripten/Wasm2JS"         },
		{ "wasm",            "Emscripten/Wasm"            },
		{ "freebsd",         "FreeBSD"                    },
		{ "linux-gcc",       "Linux (GCC compiler)"       },
		{ "linux-gcc-afl",   "Linux (GCC + AFL fuzzer)"   },
		{ "linux-clang",     "Linux (Clang compiler)"     },
		{ "linux-clang-afl", "Linux (Clang + AFL fuzzer)" },
		{ "linux-arm-gcc",   "Linux (ARM, GCC compiler)"  },
		{ "linux-ppc64le-gcc",  "Linux (PPC64LE, GCC compiler)"  },
		{ "linux-ppc64le-clang",  "Linux (PPC64LE, Clang compiler)"  },
		{ "linux-riscv64-gcc",  "Linux (RISC-V 64, GCC compiler)"  },
		{ "ios-arm",         "iOS - ARM"                  },
		{ "ios-arm64",       "iOS - ARM64"                },
		{ "ios-simulator",   "iOS - Simulator"            },
		{ "tvos-arm64",      "tvOS - ARM64"               },
		{ "xros-arm64",      "visionOS ARM64"             },
		{ "xros-simulator",  "visionOS - Simulator"       },
		{ "tvos-simulator",  "tvOS - Simulator"           },
		{ "mingw-gcc",       "MinGW"                      },
		{ "mingw-clang",     "MinGW (clang compiler)"     },
		{ "netbsd",          "NetBSD"                     },
		{ "osx-x64",         "OSX - x64"                  },
		{ "osx-arm64",       "OSX - ARM64"                },
		{ "orbis",           "Orbis"                      },
		{ "prospero",        "Prospero"                   },
		{ "riscv",           "RISC-V"                     },
		{ "rpi",             "RaspberryPi"                }
    },
}

newoption {
	trigger = "vs",
	value = "toolset",
	description = "Choose VS toolset",
	allowed = {
		{ "vs2017-clang",  "Clang with MS CodeGen"           },
		{ "vs2017-xp",     "Visual Studio 2017 targeting XP" },
		{ "winstore100",   "Universal Windows App 10.0"      },
		{ "durango",       "Durango"                         },
		{ "orbis",         "Orbis"                           },
		{ "prospero",      "Prospero"                        }
	},
}

newoption {
	trigger = "xcode",
	value = "xcode_target",
	description = "Choose XCode target",
	allowed = {
		{ "osx",  "OSX"  },
		{ "ios",  "iOS"  },
		{ "tvos", "tvOS" },
		{ "xros", "visionOS" }
	}
}

newoption {
	trigger     = "with-android",
	value       = "#",
	description = "Set Android platform version (default: android-24).",
}

newoption {
	trigger     = "with-ios",
	value       = "#",
	description = "Set iOS target version (default: 13.0).",
}

newoption {
	trigger     = "with-macos",
	value       = "#",
	description = "Set macOS target version (default 13.0).",
}

newoption {
	trigger     = "with-tvos",
	value       = "#",
	description = "Set tvOS target version (default: 13.0).",
}

newoption {
	trigger     = "with-visionos",
	value       = "#",
	description = "Set visionOS target version (default: 1.0).",
}

newoption {
	trigger = "with-windows",
	value = "#",
	description = "Set the Windows target platform version (default: $WindowsSDKVersion or 8.1).",
}

newoption {
	trigger     = "with-dynamic-runtime",
	description = "Dynamically link with the runtime rather than statically",
}

newoption {
	trigger     = "with-32bit-compiler",
	description = "Use 32-bit compiler instead 64-bit.",
}

newoption {
	trigger     = "with-avx",
	description = "Use AVX extension.",
}

newoption {
	trigger     = "with-glfw",
	description = "Links glfw libraries.",
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
if _OPTIONS["with-xros"] then
	xrosPlatform = _OPTIONS["with-xros"]
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

function getTargetOS()
	-- gmake - android
	if  (_OPTIONS["gcc"] == "android-arm") or
		(_OPTIONS["gcc"] == "android-arm64") or
		(_OPTIONS["gcc"] == "android-x86") or
		(_OPTIONS["gcc"] == "android-x86_64") then
		return "android"
	end

	-- gmake - wasm2js
	if (_OPTIONS["gcc"] == "wasm2js") or
	   (_OPTIONS["gcc"] == "wasm") then
		return "wasm2js"
	end

	-- gmake - freebsd
	if  (_OPTIONS["gcc"] == "freebsd") then
		return "bsd"
	end

	-- gmake - linux
	if	(_OPTIONS["gcc"]  == "linux-gcc") or
		(_OPTIONS["gcc"]  == "linux-gcc-afl") or
		(_OPTIONS["gcc"]  == "linux-clang") or
		(_OPTIONS["gcc"]  == "linux-clang-afl") or
		(_OPTIONS["gcc"]  == "linux-arm-gcc") or
		(_OPTIONS["gcc"]  == "linux-ppc64le-gcc") or
		(_OPTIONS["gcc"]  == "linux-ppc64le-clang") or
		(_OPTIONS["gcc"]  == "linux-riscv64-gcc") then
		return "linux"
	end

	-- gmake - ios
	-- xcode - ios	
	if	(_OPTIONS["xcode"] == "ios") or
		(_OPTIONS["gcc"]   == "ios-arm") or
		(_OPTIONS["gcc"]   == "ios-arm64") or
		(_OPTIONS["gcc"]   == "ios-simulator") then
		return "ios"
	end

	-- gmake - tvos
	-- xcode - tvos	
	if	(_OPTIONS["xcode"] == "tvos") or
		(_OPTIONS["gcc"]   == "tvos-arm64") or
		(_OPTIONS["gcc"]   == "tvos-simulator") then
		return "tvos"
	end

	-- gmake - xros
	-- xcode - xros
	if	(_OPTIONS["xcode"] == "xros") or
		(_OPTIONS["gcc"]   == "xros-arm64") or
		(_OPTIONS["gcc"]   == "xros-simulator") then
		return "xros"
	end

	-- gmake - osx
	-- xcode - osx
	if	(_OPTIONS["xcode"] == "osx") or
		(_OPTIONS["gcc"]   == "osx-x64") or
		(_OPTIONS["gcc"]   == "osx-arm64") then
		return "osx"
	end

	if _OPTIONS["gcc"] == "rpi" then
		return "rpi"
	end

	if _OPTIONS["gcc"] == "netbsd" then
		return "netbsd"
	end

	if _OPTIONS["gcc"] == "riscv" then
		return "riscv"
	end

	if _OPTIONS["gcc"] == "switch" then
		return "switch"
	end

	if  (_OPTIONS["vs"]  == "orbis") or
		(_OPTIONS["gcc"] == "orbis") then
		return "orbis"
	end

	if  (_OPTIONS["vs"]  == "prospero") or
		(_OPTIONS["gcc"] == "prospero") then
		return "prospero"
	end

	if (_OPTIONS["vs"]  == "durango") then
		return "durango"
	end
	
	-- we didn't deduce the target OS, assume host
	if (os.get() == "bsd")		then return "bsd" end
	if (os.get() == "linux")	then return "linux" end
	if (os.get() == "macosx")	then return "osx" end
	if (os.get() == "windows")	then return "windows" end

	print("ERROR: build does not support current host OS " .. os.get())
	os.exit(1)

	return ""
end

local function noCrt()

	defines {
		"RTM_NO_CRT=1",
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

function isAppleTarget()
	return getTargetOS() == "ios" or getTargetOS() == "tvos" or getTargetOS() == "osx"
end

function isWinStoreTarget()
	return getTargetOS() == "winstore81" or getTargetOS() == "winstore82"
end

function getTargetCompiler()

	-- ninja
	if	(_OPTIONS["cc"] == "gcc") then return "gcc" end
	if	(_ACTION == "ninja") and (_OPTIONS["cc"] == nil) then
		print("ERROR: Ninja action must specify target os and compiler")
		print("example: genie --cc=gcc --os=windows ninja")
		os.exit(1)
	end

	-- gmake - android
	if  (_OPTIONS["gcc"] == "android-arm")			then return "gcc-arm"				end
	if	(_OPTIONS["gcc"] == "android-arm64")		then return "gcc-arm64"				end
	if	(_OPTIONS["gcc"] == "android-x86")			then return "gcc-x86"				end
	if	(_OPTIONS["gcc"] == "android-x86_64")		then return "gcc-x86_64"			end

	-- gmake - wasm2js
	if (_OPTIONS["gcc"] == "wasm2js")				then return "wasm2js"				end
	if (_OPTIONS["gcc"] == "wasm")					then return "wasm"					end
													
	-- gmake - freebsd                      		
	if (_OPTIONS["gcc"] == "freebsd")				then return "gcc"					end

	-- gmake - linux
	if	(_OPTIONS["gcc"]  == "linux-gcc")		then return "linux-gcc"			end
	if	(_OPTIONS["gcc"]  == "linux-gcc-afl")		then return "linux-gcc-afl"		end
	if	(_OPTIONS["gcc"]  == "linux-clang")		then return "linux-clang"		end
	if	(_OPTIONS["gcc"]  == "linux-clang-afl")		then return "linux-clang-afl"		end
	if	(_OPTIONS["gcc"]  == "linux-arm-gcc")		then return "linux-arm-gcc"		end
	if	(_OPTIONS["gcc"]  == "linux-ppc64le-gcc")	then return "linux-ppc64le-gcc"		end
	if	(_OPTIONS["gcc"]  == "linux-ppc64le-clang")	then return "linux-ppc64le-clang"	end
	if	(_OPTIONS["gcc"]  == "linux-riscv64-gcc")	then return "linux-riscv64-gcc"		end

	-- gmake - ios
	-- xcode - ios	
	if (_OPTIONS["gcc"] == "ios-arm")				then return "clang-arm"				end
	if (_OPTIONS["gcc"] == "ios-arm64")				then return "clang-arm64"			end
	if (_OPTIONS["gcc"] == "ios-simulator") 		then return "clang-sim"				end
	if (_OPTIONS["xcode"] == "ios")					then return "xcode"					end
													
	-- gmake - tvos                         		
	-- xcode - tvos	                        		
	if (_OPTIONS["gcc"] == "tvos-arm64")			then return "clang-arm64"			end
	if (_OPTIONS["gcc"] == "tvos-simulator")		then return "clang-sim"				end
	if (_OPTIONS["xcode"] == "tvos")				then return "xcode"					end
													
	-- gmake - xros                         		
	-- xcode - xros	                        		
	if (_OPTIONS["gcc"] == "xros-arm64")			then return "clang-arm64"			end
	if (_OPTIONS["gcc"] == "xros-simulator")		then return "clang-sim"				end
	if (_OPTIONS["xcode"] == "xros")				then return "xcode"					end
													
	-- gmake - osx                          		
	-- xcode - osx                          		
	if (_OPTIONS["gcc"] == "osx-x64")				then return "clang"					end
	if (_OPTIONS["gcc"] == "osx-arm64")				then return "clang"					end
	if (_OPTIONS["xcode"] == "osx")					then return "xcode"					end

	-- gmake - rpi
	if (_OPTIONS["gcc"] == "rpi")					then return "gcc"					end

	-- gmake - switch
	if (_OPTIONS["gcc"] == "switch")				then return "clang"					end
	
	-- gmake - orbis
	-- visuul studio - orbis
	if (_OPTIONS["gcc"] == "orbis")					then return "orbis-clang"			end
	if (_OPTIONS["vs"]  == "orbis")					then return "orbis-clang"			end

	-- gmake - prospero
	-- visuul studio - prospero
	if (_OPTIONS["gcc"] == "prospero")				then return "prospero-clang"		end
	if (_OPTIONS["vs"]  == "prospero")				then return "prospero-clang"		end

	-- visuul studio - durango
	if (_OPTIONS["vs"]  == "durango")				then return _ACTION					end

	-- visual studio - multi
	if	(_OPTIONS["vs"] ~= nil)						then return _OPTIONS["vs"]			end
	
	-- gmake - mingw
	-- visual studio - *
	if	(_OPTIONS["gcc"] == "mingw-gcc")	then	return "mingw-gcc"		end
	if	(_OPTIONS["gcc"] == "mingw-clang")	then	return "mingw-clang"	end
	
	if (actionUsesMSVC())  then	return _ACTION	end
	if (actionUsesXcode()) then	return _ACTION	end

	print("ERROR: Target compiler could not be deduced from command line arguments")
	os.exit(1)
	return ""
end

function mkdir(_dirname)
	local dir = _dirname
	if os.is("windows") then
		dir = string.gsub( _dirname, "([/]+)", "\\" )
	else
		dir = string.gsub( _dirname, "\\\\", "\\" )
	end

	if not os.isdir(dir) then
		if not os.is("windows") then
			os.execute("mkdir -p " .. dir)
		else
			os.execute("mkdir " .. dir)
		end
	end
end

function rmdir(_dirname)
	local dir = _dirname
	if os.is("windows") then
		dir = string.gsub( _dirname, "([/]+)", "\\" )
	else
		dir = string.gsub( _dirname, "\\\\", "\\" )
	end

	if os.isdir(dir) then
		if os.is("windows") then
			dir = "rmdir /s /q " .. dir
		else
			dir = "rm -rf " .. dir
		end
		os.execute(dir)
	end
end

function executable(_path)
	if os.is("windows") then
		return _path .. ".exe"
	else
		return _path
	end
end

function getSolutionBaseDir()
	local locationDir = getTargetOS() .. "/" .. getTargetCompiler() .. "/" .. solution().name
	return path.join(RTM_BUILD_DIR, locationDir)
end

function getLocationDir()
	return getSolutionBaseDir() .. "/projects/"
end

function toolchain()

	-- Avoid error when invoking genie --help.
	if (_ACTION == nil) then return false end

	local fullLocation = getLocationDir()

	RTM_LOCATION_PATH = fullLocation
	location (fullLocation)
	mkdir(fullLocation)

	if _ACTION == "clean" then
		rmdir(RTM_BUILD_DIR)
	end

	if _OPTIONS["with-android"] then
		androidTarget = _OPTIONS["with-android"]
		androidPlatform = "android-" .. androidTarget
	end

	if _OPTIONS["with-ios"] then
		iosPlatform = _OPTIONS["with-ios"]
	end

	if _ACTION == "gmake" then

		if nil == _OPTIONS["gcc"] then
			print("ERROR: GCC flavor must be specified!")
			os.exit(1)
		end

		if "android-arm"    == _OPTIONS["gcc"]
		or "android-arm64"  == _OPTIONS["gcc"]
		or "android-x86"    == _OPTIONS["gcc"]
		or "android-x86_64" == _OPTIONS["gcc"] then

			if not os.getenv("ANDROID_NDK_ARM") or not os.getenv("ANDROID_NDK_CLANG") or not os.getenv("ANDROID_NDK_ROOT") then
				print("Set ANDROID_NDK_ARM, ANDROID_NDK_CLANG, and ANDROID_NDK_ROOT environment variables.")
			end 

			premake.gcc.cc   = androidToolchainRoot() .. "/bin/clang"
			premake.gcc.cxx  = androidToolchainRoot() .. "/bin/clang++"
			premake.gcc.ar   = androidToolchainRoot() .. "/bin/llvm-ar"
			premake.gcc.llvm = true

		elseif "wasm2js" == _OPTIONS["gcc"] or "wasm" == _OPTIONS["gcc"] then

			if not os.getenv("EMSCRIPTEN") then
				print("Please set EMSCRIPTEN enviroment variable to point to directory where emcc can be found.")
				os.exit()
			end

			premake.gcc.cc   = "\"$(EMSCRIPTEN)/emcc\""
			premake.gcc.cxx  = "\"$(EMSCRIPTEN)/em++\""
			premake.gcc.ar   = "\"$(EMSCRIPTEN)/emar\""
			premake.gcc.llvm = true
			premake.gcc.namestyle = "Emscripten"
			--location (path.join(_buildDir, "projects", _ACTION .. "-" .. _OPTIONS["gcc"]))

		elseif "freebsd" == _OPTIONS["gcc"] then
			--location (path.join(_buildDir, "projects", _ACTION .. "-freebsd"))

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

		elseif "linux-gcc-afl" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "afl-gcc"
			premake.gcc.cxx = "afl-g++"
			premake.gcc.ar  = "ar"
			--location (path.join(_buildDir, "projects", _ACTION .. "-linux"))

		elseif "linux-clang" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "clang"
			premake.gcc.cxx = "clang++"
			premake.gcc.ar  = "ar"
			--location (path.join(_buildDir, "projects", _ACTION .. "-linux-clang"))

		elseif "linux-clang-afl" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "afl-clang"
			premake.gcc.cxx = "afl-clang++"
			premake.gcc.ar  = "ar"
			--location (path.join(_buildDir, "projects", _ACTION .. "-linux-clang"))

		elseif "linux-arm-gcc" == _OPTIONS["gcc"] then
			--location (path.join(_buildDir, "projects", _ACTION .. "-linux-arm-gcc"))

		elseif "linux-ppc64le-gcc" == _OPTIONS["gcc"] then
 			--location (path.join(_buildDir, "projects", _ACTION .. "-linux-ppc64le-gcc"))

		elseif "linux-ppc64le-clang" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "clang"
			premake.gcc.cxx = "clang++"
			premake.gcc.ar  = "ar"
			premake.gcc.llvm = true
			--location (path.join(_buildDir, "projects", _ACTION .. "-linux-ppc64le-clang"))

		elseif "linux-riscv64-gcc" == _OPTIONS["gcc"] then
			--location (path.join(_buildDir, "projects", _ACTION .. "-linux-riscv64-gcc"))

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
			--location (path.join(_buildDir, "projects", _ACTION .. "-mingw-gcc"))

		elseif "mingw-clang" == _OPTIONS["gcc"] then

			premake.gcc.cc   = "$(CLANG)/bin/clang"
			premake.gcc.cxx  = "$(CLANG)/bin/clang++"
			premake.gcc.ar   = "$(MINGW)/bin/ar"
--			premake.gcc.ar   = "$(CLANG)/bin/llvm-ar"
--			premake.gcc.llvm = true
			location (path.join(_buildDir, "projects", _ACTION .. "-mingw-clang"))

		elseif "netbsd" == _OPTIONS["gcc"] then
			location (path.join(_buildDir, "projects", _ACTION .. "-netbsd"))

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

			--location (path.join(_buildDir, "projects", _ACTION .. "-" .. _OPTIONS["gcc"]))

		elseif "orbis" == _OPTIONS["gcc"] then

			if not os.getenv("SCE_ORBIS_SDK_DIR") then
				print("Set SCE_ORBIS_SDK_DIR environment variable.")
			end

			orbisToolchain = "$(SCE_ORBIS_SDK_DIR)/host_tools/bin/orbis-"

			quote = "";
			if os.is("windows") then
				quote = '"'
			end
			premake.gcc.cc  = quote .. orbisToolchain .. "clang" .. quote
			premake.gcc.cxx = quote .. orbisToolchain .. "clang++" .. quote
			premake.gcc.ar  = quote .. orbisToolchain .. "ar" .. quote
			--location (path.join(_buildDir, "projects", _ACTION .. "-orbis"))

		elseif "prospero" == _OPTIONS["gcc"] then

			if not os.getenv("SCE_PROSPERO_SDK_DIR") then
				print("Set SCE_PROSPERO_SDK_DIR environment variable.")
			end

			prosperoToolchain = "$(SCE_PROSPERO_SDK_DIR)/host_tools/bin/prospero-"

			quote = "";
			if os.is("windows") then
				quote = '"'
			end
			premake.gcc.cc  = quote .. prosperoToolchain .. "clang" .. quote
			premake.gcc.cxx = quote .. prosperoToolchain .. "clang" .. quote
			premake.gcc.ar  = quote .. prosperoToolchain .. "llvm-ar" .. quote
			--location (path.join(_buildDir, "projects", _ACTION .. "-prospero"))

		elseif "rpi" == _OPTIONS["gcc"] then

		elseif "switch" == _OPTIONS["gcc"] then

			if not os.getenv("NINTENDO_SDK_ROOT") then
				print("Set NINTENDO_SDK_ROOT environment variable.")
			end

			nintendoToolchain = "\"$(NINTENDO_SDK_ROOT)/Compilers/NX/nx/aarch64/bin/"

			premake.gcc.cc  = nintendoToolchain .. "clang\""
			premake.gcc.cxx = nintendoToolchain .. "clang++\""
			premake.gcc.ar  = nintendoToolchain .. "aarch64-nintendo-nx-elf-ar\""

		elseif "riscv" == _OPTIONS["gcc"] then
			premake.gcc.cc  = "$(FREEDOM_E_SDK)/work/build/riscv-gnu-toolchain/riscv64-unknown-elf/prefix/bin/riscv64-unknown-elf-gcc"
			premake.gcc.cxx = "$(FREEDOM_E_SDK)/work/build/riscv-gnu-toolchain/riscv64-unknown-elf/prefix/bin/riscv64-unknown-elf-g++"
			premake.gcc.ar  = "$(FREEDOM_E_SDK)/work/build/riscv-gnu-toolchain/riscv64-unknown-elf/prefix/bin/riscv64-unknown-elf-ar"
			location (path.join(_buildDir, "projects", _ACTION .. "-riscv"))

		end

		elseif _ACTION == "vs2022" or _ACTION == "vs2019" or _ACTION == "vs2017" then

			local action = premake.action.current()
			if nil ~= windowsPlatform then
				action.vstudio.windowsTargetPlatformVersion    = windowsPlatform
				action.vstudio.windowsTargetPlatformMinVersion = windowsPlatform
			end

			if (_ACTION .. "-clang") == _OPTIONS["vs"] then
				if "vs2017-clang" == _OPTIONS["vs"] then
					premake.vstudio.toolset = "v141_clang_c2"
				else
					premake.vstudio.toolset = ("LLVM-" .. _ACTION)
				end
				location (path.join(_buildDir, "projects", _ACTION .. "-clang"))

			elseif "winstore100" == _OPTIONS["vs"] then
				premake.vstudio.toolset = "v141"
				premake.vstudio.storeapp = "10.0"

				platforms { "ARM" }
				location (path.join(_buildDir, "projects", _ACTION .. "-winstore100"))

			elseif "durango" == _OPTIONS["vs"] then
				if not os.getenv("DurangoXDK") then
					print("DurangoXDK not found.")
				end

				premake.vstudio.toolset = "v140"
				premake.vstudio.storeapp = "durango"
				platforms { "Durango" }
				location (path.join(_buildDir, "projects", _ACTION .. "-durango"))
			elseif "orbis" == _OPTIONS["vs"] then

				if not os.getenv("SCE_ORBIS_SDK_DIR") then
					print("Set SCE_ORBIS_SDK_DIR environment variable.")
				end

				platforms { "Orbis" }
				location (path.join(_buildDir, "projects", _ACTION .. "-orbis"))
			elseif "prospero" == _OPTIONS["vs"] then

				if not os.getenv("SCE_PROSPERO_SDK_DIR") then
					print("Set SCE_PROSPERO_SDK_DIR environment variable.")
				end

				platforms { "Prospero" }
				location (path.join(_buildDir, "projects", _ACTION .. "-prospero"))
		end

	elseif _ACTION and _ACTION:match("^xcode.+$") then
		local action = premake.action.current()
		local str_or = function(str, def)
			return #str > 0 and str or def
		end

		if "osx" == _OPTIONS["xcode"] then
			action.xcode.macOSTargetPlatformVersion = str_or(macosPlatform, "13.0")
			premake.xcode.toolset = "macosx"
			location (path.join(_buildDir, "projects", _ACTION .. "-osx"))

		elseif "ios" == _OPTIONS["xcode"] then
			action.xcode.iOSTargetPlatformVersion = str_or(iosPlatform, "13.0")
			premake.xcode.toolset = "iphoneos"
			location (path.join(_buildDir, "projects", _ACTION .. "-ios"))

		elseif "tvos" == _OPTIONS["xcode"] then
			action.xcode.tvOSTargetPlatformVersion = str_or(tvosPlatform, "13.0")
			premake.xcode.toolset = "appletvos"
			location (path.join(_buildDir, "projects", _ACTION .. "-tvos"))

		elseif "xros" == _OPTIONS["xcode"] then
			action.xcode.visionOSTargetPlatformVersion = str_or(xrosPlatform, "1.0")
			premake.xcode.toolset = "xros"
			location (path.join(_buildDir, "projects", _ACTION .. "-xros"))
		end
	end

	if not _OPTIONS["with-dynamic-runtime"] then
		flags { "StaticRuntime" }
	end

	if _OPTIONS["with-avx"] then
		flags { "EnableAVX" }
	end

	if _OPTIONS["with-crtnone"] then
		crtNone()
	end

	configuration {} -- reset configuration

	return true
end

function getBuildDirRoot(_platform, _configuration)
	return getSolutionBaseDir() .. "/" .. _platform .. "/" .. _configuration .. "/"
end

function commonConfig(_platform, _configuration, _isLib, _isSharedLib, _executable)

	local buildRoot = getBuildDirRoot(_platform, _configuration)
	local binDir = buildRoot .. "bin/"
	local libDir = buildRoot .. "lib/"
	local objDir = buildRoot .. "obj/" .. project().name .. "/"

	mkdir(binDir)
	mkdir(libDir)
	mkdir(objDir)

	if _isLib and not _isSharedLib then
		binDir = libDir
	end

	configuration { _platform, _configuration }
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
		includedirs { path.join(find3rdPartyProject("bx"), "include/compat/msvc") }
		includedirs { path.join(getProjectPath("rbase"), "inc/compat/msvc") }
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
			"/std:c++17",
			"/Ob2"		-- The Inline Function Expansion
		}
		linkoptions {
			"/ignore:4221", -- LNK4221: This object file does not define any previously undefined public symbols, so it will not be used by any link operation that consumes this library
		}

	configuration { "linux*", _platform, _configuration }
		includedirs { path.join(find3rdPartyProject("bx"), "include/compat/linux") }

	configuration { "vs*", "not NX32", "not NX64", _platform, _configuration }
		flags {	"EnableAVX" }

	configuration { "vs2008", _platform, _configuration }
		includedirs { path.join(find3rdPartyProject("bx"), "include/compat/pre1600") }
		includedirs { path.join(getProjectPath("rbase"), "inc/compat/msvc/pre1600") }

	configuration { "x32", "vs*", "not orbis", "not prospero", _platform, _configuration }
		defines { "RTM_WIN32", "RTM_WINDOWS" }

	configuration { "x64", "vs*", "not orbis", "not prospero", _platform, _configuration }
		defines { "RTM_WIN64", "RTM_WINDOWS", "_WIN64" }

	configuration { "ARM", "vs*", "not orbis", "not prospero", _platform, _configuration }

	configuration { "vs*-clang", _platform, _configuration }
		buildoptions {
			"-Qunused-arguments",
		}

	configuration { "x32", "vs*-clang", _platform, _configuration }
		defines { "RTM_WIN32", "RTM_WINDOWS" }

	configuration { "x64", "vs*-clang", _platform, _configuration }
		defines { "RTM_WIN64", "RTM_WINDOWS" }

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
		if not IS_3RD_PARTY then
			buildoptions {
				"-Wshadow",
			}
		end

	configuration { "mingw-*", _platform, _configuration }
		defines { "WIN32" }
		includedirs { path.join(find3rdPartyProject("bx"), "include/compat/mingw") }
		includedirs { path.join(getProjectPath("rbase"), "inc/compat/mingw") }

		defines {
			"MINGW_HAS_SECURE_API=1",
		}
		buildoptions {
			"-Wunused-value",
			"-fdata-sections",
			"-ffunction-sections",
			"-msse4.2",
			"-Wunused-value",
			"-Wundef",
		}
		linkoptions {
			"-Wl,--gc-sections",
			"-static",
			"-static-libgcc",
			"-static-libstdc++",
		}
		if EXECUTABLE then
		links { 
			"ole32",
			"oleaut32",
			"uuid",
			"gdi32"
		}
		end

	configuration { "linux-*", _platform, _configuration }
		if EXECUTABLE then
		links {
			"pthread",
		}
		end

	configuration { "osx-*", _platform, _configuration }
		if EXECUTABLE then
		linkoptions {
			"-framework Foundation",
			"-framework IOKit",
			"-framework AppKit",
			"-framework QuartzCore",
			"-framework Metal"
		}
		end

	configuration { "x32", "mingw-gcc", _platform, _configuration }
		defines { "RTM_WIN32", "RTM_WINDOWS", "WINVER=0x0601", "_WIN32_WINNT=0x0601" }
		buildoptions { "-m32" }
		libdirs {
			"$(MINGW)/x86_64-w64-mingw32/lib32"
		}

	configuration { "x64", "mingw-gcc", _platform, _configuration }
		defines { "RTM_WIN64", "RTM_WINDOWS", "WINVER=0x0601", "_WIN32_WINNT=0x0601" }
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
		defines { "RTM_WIN32", "RTM_WINDOWS", "WINVER=0x0601", "_WIN32_WINNT=0x0601" }
		buildoptions { "-m32" }

	configuration { "x64", "mingw-clang", _platform, _configuration }
		defines { "RTM_WIN64", "RTM_WINDOWS", "WINVER=0x0601", "_WIN32_WINNT=0x0601" }
		libdirs {
			"$(GLES_X64_DIR)",
		}
		buildoptions { "-m64" }

	configuration { "linux-clang", _platform, _configuration }

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
		defines { "RTM_ANDROID" }
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
			"--gcc-toolchain=" .. androidToolchainRoot(),
			"--sysroot=" .. androidToolchainRoot() .. "/sysroot",
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
			"--gcc-toolchain=" .. androidToolchainRoot(),
			"--sysroot=" .. androidToolchainRoot() .. "/sysroot",
			"-no-canonical-prefixes",
			"-Wl,--no-undefined",
			"-Wl,-z,noexecstack",
			"-Wl,-z,relro",
			"-Wl,-z,now",
		}
		if EXECUTABLE then
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
		
	configuration { "wasm2js or wasm ", _platform, _configuration }
		defines { "RTM_ASMJS" }
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
		defines { "RTM_FREEBSD" }
		includedirs { path.join(find3rdPartyProject("bx"), "include/compat/freebsd") }
		includedirs { path.join(getProjectPath("rbase"), "inc/compat/freebsd") }

	configuration { "durango", _platform, _configuration }
		includedirs { path.join(find3rdPartyProject("bx"), "include/compat/msvc") }
		includedirs { path.join(getProjectPath("rbase"), "inc/compat/msvc")	}
		removeflags { 
			"StaticRuntime", 
			"NoExceptions" 
		}
		buildoptions { "/EHsc /await /std:c++latest" }
		linkoptions { "/ignore:4264" }


	configuration { "Xbox360", _platform, _configuration }
		defines { "RTM_XBOX360" }
		includedirs { path.join(find3rdPartyProject("bx"), "include/compat/msvc") }
		includedirs { path.join(getProjectPath("rbase"), "inc/compat/msvc") }
		defines {
			"NOMINMAX",
			"_XBOX",
		}

	configuration { "osx-x64", _platform, _configuration }
		defines { "RTM_OSX" }
		linkoptions {
			"-arch x86_64",
		}
		buildoptions {
			"-arch x86_64",
			"-msse4.2",
			"-target x86_64-apple-macos" .. (#macosPlatform > 0 and macosPlatform or "13.0"),
		}

	configuration { "osx-arm64", _platform, _configuration }
		defines { "RTM_OSX" }
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
		includedirs { path.join(find3rdPartyProject("bx"), "include/compat/osx") }
		includedirs { path.join(getProjectPath("rbase"), "inc/compat/osx") }

	configuration { "ios*", _platform, _configuration }
		defines { "RTM_IOS" }
		linkoptions {
			"-lc++",
		}
		buildoptions {
			"-Wfatal-errors",
			"-Wunused-value",
			"-Wundef",
		}
		includedirs { path.join(find3rdPartyProject("bx"), "include/compat/ios") }
		includedirs { path.join(getProjectPath("rbase"), "inc/compat/ios") }

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
		linkoptions {
			"-lc++",
		}
		buildoptions {
			"-Wfatal-errors",
			"-Wunused-value",
			"-Wundef",
		}
		includedirs { path.join(find3rdPartyProject("bx"), "include/compat/ios") }
		includedirs { path.join(getProjectPath("rbase"), "inc/compat/ios") }

	configuration { "xros-arm64", _platform, _configuration }
		linkoptions {
			"--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/XROS.platform/Developer/SDKs/XROS" ..xrosPlatform.. ".sdk",
			"-L/Applications/Xcode.app/Contents/Developer/Platforms/XROS.platform/Developer/SDKs/XROS" ..xrosPlatform .. ".sdk/usr/lib/system",
			"-F/Applications/Xcode.app/Contents/Developer/Platforms/XROS.platform/Developer/SDKs/XROS" ..xrosPlatform .. ".sdk/System/Library/Frameworks",
			"-F/Applications/Xcode.app/Contents/Developer/Platforms/XROS.platform/Developer/SDKs/XROS" ..xrosPlatform .. ".sdk/System/Library/PrivateFrameworks",
		}
		buildoptions {
			"--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/XROS.platform/Developer/SDKs/XROS" ..tvosPlatform .. ".sdk",
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
		linkoptions {
			"-lc++",
		}
		buildoptions {
			"-Wfatal-errors",
			"-Wunused-value",
			"-Wundef",
		}
		includedirs { path.join(find3rdPartyProject("bx"), "include/compat/ios") }
		includedirs { path.join(getProjectPath("rbase"), "inc/compat/ios") }

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
		includedirs {
			path.join(find3rdPartyProject("bx"), "include/compat/freebsd"),
			path.join(getProjectPath("rbase"), "inc/compat/freebsd"),
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
		includedirs {
			path.join(find3rdPartyProject("bx"), "include/compat/freebsd"),
			path.join(getProjectPath("rbase"), "inc/compat/freebsd"),
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
		libdirs {
			path.join(_libDir, "lib/rpi"),
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
		targetdir (path.join(_buildDir, "riscv/bin"))
		objdir (path.join(_buildDir, "riscv/obj"))
		defines {
			"__BSD_VISIBLE",
			"__MISC_VISIBLE",
		}
		includedirs {
			"$(FREEDOM_E_SDK)/work/build/riscv-gnu-toolchain/riscv64-unknown-elf/prefix/riscv64-unknown-elf/include",
			path.join(find3rdPartyProject("bx"), "include/compat/riscv"),
			path.join(getProjectPath("rbase"), "inc/compat/riscv"),
		}
		buildoptions {
			"-Wunused-value",
			"-Wundef",
			"--sysroot=$(FREEDOM_E_SDK)/work/build/riscv-gnu-toolchain/riscv64-unknown-elf/prefix/riscv64-unknown-elf",
		}

	configuration { "durango", _platform, _configuration }
		defines { "NOMINMAX" }
		links {
			"d3d11_x",
			"d3d12_x",
			"combase",
			"kernelx"
		}

	configuration { "rpi", _platform, _configuration }
		defines { "RTM_RPI" }
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

	configuration { "switch", _platform, _configuration }
		defines { "RTM_SWITCH" }
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
	configuration { "switch", "debug", _platform, _configuration }
		defines { "NN_SDK_BUILD_DEVELOP" }
	configuration { "switch", "retail", _platform, _configuration }
		defines { "NN_SDK_BUILD_RELEASE" }

	if _executable then
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

	if _OPTIONS["deploy"] ~= nil and EXECUTABLE then
		prepareProjectDeployment(_platform, _configuration, binDir)
	end
end

function strip()

	configuration { "android-*", "Release" or "Retail" }
		postbuildcommands {
			"$(SILENT) echo Stripping symbols.",
			"$(SILENT) " .. androidToolchainRoot() .. "/bin/llvm-strip -s \"$(TARGET)\""
		}

	configuration { "linux-* or rpi", "Release" or "Retail" }
		postbuildcommands {
			"$(SILENT) echo Stripping symbols.",
			"$(SILENT) strip -s \"$(TARGET)\""
		}

	configuration { "mingw*", "Release" or "Retail" }
		postbuildcommands {
			"$(SILENT) echo Stripping symbols.",
			"$(SILENT) $(MINGW)/bin/strip -s \"$(TARGET)\""
		}

	configuration { "riscv" }
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


function actionTargetsWASM()
	return (_OPTIONS["gcc"] == "wasm") or (_OPTIONS["gcc"] == "wasm2js")
end

-- has to be called from an active solution
function setPlatforms()
	if actionUsesXcode() then --actionTargetsWASM() then
		configurations { "release" }
		platforms { "Universal" }
	elseif actionUsesMSVC() then
		if  not (getTargetOS() == "durango")	and 
			not (getTargetOS() == "orbis")		and
			not (getTargetOS() == "prospero")	and
			not (getTargetOS() == "winstore81")	and
			not (getTargetOS() == "winstore82") 
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
