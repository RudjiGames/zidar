--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

--- Free, easy, portable audio engine for games
--- https://github.com/jarikomppa/soloud

local params		= { ... }
local SOLOUD_ROOT = params[1]

local SOLOUD_FILES = {
	SOLOUD_ROOT .. "/src/core/**.cpp",
	SOLOUD_ROOT .. "/src/audiosource/**.cpp",
	SOLOUD_ROOT .. "/*.h"
}

local WITH_SDL = 0
local WITH_SDL2 = 0
local WITH_SDL_STATIC = 0
local WITH_SDL2_STATIC = 0
local WITH_PORTAUDIO = 0
local WITH_OPENAL = 0
local WITH_XAUDIO2 = 0
local WITH_WINMM = 0
local WITH_WASAPI = 0
local WITH_ALSA = 0
local WITH_JACK = 0
local WITH_OSS = 0
local WITH_COREAUDIO = 0
local WITH_VITA_HOMEBREW = 0
local WITH_NOSOUND = 0
local WITH_MINIAUDIO = 0
local WITH_NULL = 1
local WITH_TOOLS = 0

	if getTargetOS() == "windows"	then	WITH_WINMM		= 1
elseif getTargetOS() == "osx"		then	WITH_COREAUDIO	= 1
elseif getTargetOS() == "asmjs"		then	WITH_MINIAUDIO	= 1
else
	WITH_ALSA = 1
	WITH_OSS = 1
end

--------------------------------------------------------------
local sdl_root       	= "/libraries/sdl"
local sdl2_root      	= "/libraries/sdl2"
local dxsdk_root     	= os.getenv("DXSDK_DIR") and os.getenv("DXSDK_DIR") or "C:/Program Files (x86)/Microsoft DirectX SDK (June 2010)"
local portaudio_root 	= "/libraries/portaudio"
local openal_root    	= "/libraries/openal"

--------------------------------------------------------------
local sdl_include       = sdl_root .. "/include"
local sdl2_include      = sdl2_root .. "/include"
local sdl2_lib_x86      = sdl2_root .. "/lib/x86"
local sdl2_lib_x64      = sdl2_root .. "/lib/x64"
local dxsdk_include     = dxsdk_root .. "/include"
local portaudio_include = portaudio_root .. "/include"
local openal_include    = openal_root .. "/include"

--------------------------------------------------------------

newoption {
    trigger       = "with-common-backends",
    description   = "Includes common backends in build"
}

newoption {
	trigger		  = "with-openal",
	description = "Include OpenAL backend in build"
}

newoption {
	trigger		  = "with-sdl",
	description = "Include SDL backend in build"
}

newoption {
	trigger		  = "with-sdl2",
	description = "Include SDL2 backend in build"
}

newoption {
	trigger		  = "with-portaudio",
	description = "Include PortAudio backend in build"
}

newoption {
	trigger		  = "with-wasapi",
	description = "Include WASAPI backend in build"
}

newoption {
	trigger		  = "with-xaudio2",
	description = "Include XAudio2 backend in build"
}

newoption {
	trigger		  = "with-native-only",
	description = "Only native backends (winmm/oss) in build (default)"
}

newoption {
	trigger		  = "with-sdl-only",
	description = "Only include sdl in build"
}

newoption {
	trigger		  = "with-sdlstatic-only",
	description = "Only include sdl that doesn't use dyndll in build"
}

newoption {
	trigger		  = "with-sdl2-only",
	description = "Only include sdl2 in build"
}

newoption {
	trigger		  = "with-sdl2static-only",
	description = "Only include sdl2 that doesn't use dyndll in build"
}

newoption {
	trigger		  = "with-coreaudio",
	description = "Include OS X CoreAudio backend in build"
}

newoption {
	trigger		  = "with-vita-homebrew-only",
	description = "Only include PS Vita homebrew backend in build"
}

newoption {
	trigger		  = "with-tools",
	description = "Include (optional) tools in build"
}

newoption {
	trigger		  = "soloud-devel",
	description = "Shorthand for options used while developing SoLoud"
}

newoption {
	trigger		  = "with-nosound",
	description = "Include nosound backend in build"
}

newoption {
	trigger		  = "with-jack",
	description = "Include JACK backend in build"
}

newoption {
	trigger		  = "with-jack-only",
	description = "Only include JACK backend in build"
}

newoption {
    trigger       = "with-miniaudio",
    description = "Include MiniAudio in build" 
}

newoption {
    trigger       = "with-miniaudio-only",
    description = "Only include MiniAudio in build"
}

if _OPTIONS["soloud-devel"] then
    WITH_SDL = 0
    WITH_SDL2 = 1
    WITH_SDL_STATIC = 0
    WITH_SDL2_STATIC = 0
    WITH_PORTAUDIO = 1
    WITH_OPENAL = 1
    WITH_XAUDIO2 = 0
    WITH_WINMM = 0
    WITH_WASAPI = 0
    WITH_MINIAUDIO = 1
    WITH_OSS = 1
    WITH_NOSOUND = 1
    if (os.is("Windows")) then
    	WITH_XAUDIO2 = 0
    	WITH_WINMM = 1
    	WITH_WASAPI = 1
    	WITH_OSS = 0
    end
    WITH_TOOLS = 1
end

if _OPTIONS["with-common-backends"] then
    WITH_SDL = 1
    WITH_SDL_STATIC = 0
    WITH_SDL2_STATIC = 0
    WITH_PORTAUDIO = 1
    WITH_OPENAL = 1
    WITH_XAUDIO2 = 0
    WITH_WINMM = 0
    WITH_WASAPI = 0
    WITH_OSS = 1
    WITH_NOSOUND = 1
    WITH_MINIAUDIO = 0

    if (os.is("Windows")) then
    	WITH_XAUDIO2 = 0
    	WITH_WINMM = 1
    	WITH_WASAPI = 1
    	WITH_OSS = 0
    end
end

if _OPTIONS["with-xaudio2"] then
	WITH_XAUDIO2 = 1
end

if _OPTIONS["with-openal"] then
	WITH_OPENAL = 1
end

if _OPTIONS["with-portaudio"] then
	WITH_PORTAUDIO = 1
end

if _OPTIONS["with-coreaudio"] then
	WITH_COREAUDIO = 1
end

if _OPTIONS["with-sdl"] then
	WITH_SDL = 1
end

if _OPTIONS["with-sdl2"] then
	WITH_SDL2 = 1
end

if _OPTIONS["with-wasapi"] then
	WITH_WASAPI = 1
end

if _OPTIONS["with-nosound"] then
    WITH_NOSOUND = 1
end

if _OPTIONS["with-sdl-only"] then
	WITH_SDL = 1
	WITH_SDL2 = 0
	WITH_SDL_STATIC = 0
	WITH_SDL2_STATIC = 0
	WITH_PORTAUDIO = 0
	WITH_OPENAL = 0
	WITH_XAUDIO2 = 0
	WITH_WINMM = 0
	WITH_WASAPI = 0
	WITH_OSS = 0
	WITH_NOSOUND = 0
	WITH_MINIAUDIO = 0
end

if _OPTIONS["with-sdl2-only"] then
	WITH_SDL = 0
	WITH_SDL2 = 1
	WITH_SDL_STATIC = 0
	WITH_SDL2_STATIC = 0
	WITH_PORTAUDIO = 0
	WITH_OPENAL = 0
	WITH_XAUDIO2 = 0
	WITH_WINMM = 0
	WITH_WASAPI = 0
	WITH_OSS = 0
	WITH_NOSOUND = 0
	WITH_MINIAUDIO = 0
end

if _OPTIONS["with-sdlstatic-only"] then
	WITH_SDL = 0
	WITH_SDL2 = 0
	WITH_SDL_STATIC = 1
	WITH_PORTAUDIO = 0
	WITH_OPENAL = 0
	WITH_XAUDIO2 = 0
	WITH_WINMM = 0
	WITH_WASAPI = 0
	WITH_OSS = 0
	WITH_NOSOUND = 0
	WITH_MINIAUDIO = 0
end

if _OPTIONS["with-sdl2static-only"] then
	WITH_SDL = 0
	WITH_SDL2 = 0
	WITH_SDL_STATIC = 0
	WITH_SDL2_STATIC = 1
	WITH_PORTAUDIO = 0
	WITH_OPENAL = 0
	WITH_XAUDIO2 = 0
	WITH_WINMM = 0
	WITH_WASAPI = 0
	WITH_OSS = 0
	WITH_NOSOUND = 0
	WITH_MINIAUDIO = 0
end

if _OPTIONS["with-sdl2static-only"] then
	WITH_SDL = 0
	WITH_SDL2 = 0
	WITH_SDL_STATIC = 0
	WITH_SDL2_STATIC = 1
	WITH_PORTAUDIO = 0
	WITH_OPENAL = 0
	WITH_XAUDIO2 = 0
	WITH_WINMM = 0
	WITH_WASAPI = 0
	WITH_OSS = 0
	WITH_NOSOUND = 0
	WITH_MINIAUDIO = 0
end

if _OPTIONS["with-vita-homebrew-only"] then
	WITH_SDL = 0
	WITH_SDL2 = 0
	WITH_SDL_STATIC = 0
	WITH_SDL2_STATIC = 0
	WITH_PORTAUDIO = 0
	WITH_OPENAL = 0
	WITH_XAUDIO2 = 0
	WITH_WINMM = 0
	WITH_WASAPI = 0
	WITH_OSS = 0
	WITH_ALSA = 0
	WITH_VITA_HOMEBREW = 1
	WITH_NOSOUND = 0
	WITH_MINIAUDIO = 0

	premake.gcc.cc = "arm-vita-eabi-gcc"
	premake.gcc.cxx = "arm-vita-eabi-g++"
	premake.gcc.ar = "arm-vita-eabi-ar"
end

if _OPTIONS["with-jack"] then
	WITH_JACK = 1
end

if _OPTIONS["with-jack-only"] then
	WITH_SDL = 0
	WITH_SDL2 = 0
	WITH_SDL_STATIC = 0
	WITH_SDL2_STATIC = 0
	WITH_PORTAUDIO = 0
	WITH_OPENAL = 0
	WITH_XAUDIO2 = 0
	WITH_WINMM = 0
	WITH_WASAPI = 0
	WITH_OSS = 0
	WITH_ALSA = 0
	WITH_VITA_HOMEBREW = 0
	WITH_COREAUDIO = 0
	WITH_JACK = 1
	WITH_NOSOUND = 0
	WITH_MINIAUDIO = 0
end

if _OPTIONS["with-miniaudio"] then
    WITH_MINIAUDIO = 1
end

if _OPTIONS["with-miniaudio-only"] then
	WITH_SDL = 0
	WITH_SDL2 = 0
	WITH_SDL_STATIC = 0
	WITH_SDL2_STATIC = 0
	WITH_PORTAUDIO = 0
	WITH_OPENAL = 0
	WITH_XAUDIO2 = 0
	WITH_WINMM = 0
	WITH_WASAPI = 0
	WITH_OSS = 0
	WITH_ALSA = 0
	WITH_VITA_HOMEBREW = 0
	WITH_COREAUDIO = 0
	WITH_JACK = 0
	WITH_NOSOUND = 0
	WITH_MINIAUDIO = 1
end

if _OPTIONS["with-native-only"] then
	WITH_SDL = 0
	WITH_SDL2 = 0
	WITH_SDL_STATIC = 0
	WITH_SDL2_STATIC = 0
	WITH_PORTAUDIO = 0
	WITH_OPENAL = 0
	WITH_XAUDIO2 = 0
	WITH_WINMM = 0
	WITH_WASAPI = 0
	WITH_OSS = 0
	WITH_MINIAUDIO = 0
	WITH_NOSOUND = 0
	if (os.is("Windows")) then
		WITH_WINMM = 1
	elseif (os.is("macosx")) then
		WITH_COREAUDIO = 1
	else
	  WITH_OSS = 1
	end
end

if _OPTIONS["with-tools"] then
	WITH_TOOLS = 1
end

print ("")
print ("SoLoud active options:")
print ("WITH_SDL           = ", WITH_SDL)
print ("WITH_SDL2          = ", WITH_SDL2)
print ("WITH_PORTAUDIO     = ", WITH_PORTAUDIO)
print ("WITH_OPENAL        = ", WITH_OPENAL)
print ("WITH_XAUDIO2       = ", WITH_XAUDIO2)
print ("WITH_WINMM         = ", WITH_WINMM)
print ("WITH_WASAPI        = ", WITH_WASAPI)
print ("WITH_ALSA          = ", WITH_ALSA)
print ("WITH_JACK          = ", WITH_JACK)
print ("WITH_OSS           = ", WITH_OSS)
print ("WITH_MINIAUDIO     = ", WITH_MINIAUDIO)
print ("WITH_NOSOUND       = ", WITH_NOSOUND)
print ("WITH_COREAUDIO     = ", WITH_COREAUDIO)
print ("WITH_VITA_HOMEBREW = ", WITH_VITA_HOMEBREW)
print ("WITH_TOOLS         = ", WITH_TOOLS)
print ("")

--------------------------------------------------------------

function projectExtraConfig_soloud()
	includedirs { SOLOUD_ROOT .. "/include" }
	if (WITH_VITA_HOMEBREW == 0) then
		configuration { "x64 and not arm64x" }
			buildoptions { 
				"-msse4.1 -msimd128", 
				"-fPIC"
			}
	end

	configuration {}
	if (WITH_ALSA == 1) then
		links {"asound"}
	end
	if (WITH_JACK == 1) then
		links { "jack" }
	end
	if (WITH_COREAUDIO == 1) then
		links {"AudioToolbox.framework"}
	end
--	links {"SoloudStatic"}
	if (not os.is("windows")) then
		links { "pthread" }
		links { "dl" }
	end

	if (WITH_OPENAL == 1) then
		defines {"WITH_OPENAL"}
		files {
		  SOLOUD_ROOT .. "/src/backend/openal/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include",
		  openal_include
		}
	end

	if (WITH_ALSA == 1) then
		defines {"WITH_ALSA"}
		files {
		  SOLOUD_ROOT .. "/src/backend/alsa/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include"
		}
	end

	if (WITH_OSS == 1) then
		defines {"WITH_OSS"}
		files {
		  SOLOUD_ROOT .. "/src/backend/oss/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include"
		}
	end

	if (WITH_MINIAUDIO == 1) then
		defines {"WITH_MINIAUDIO"}
		files {
		  SOLOUD_ROOT .. "/src/backend/miniaudio/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include"
		}
	end

	if (WITH_NOSOUND == 1) then
		defines {"WITH_NOSOUND"}
		files {
		  SOLOUD_ROOT .. "/src/backend/nosound/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include"
		}
	end

	if (WITH_COREAUDIO == 1) then
		defines {"WITH_COREAUDIO"}
		files {
		  SOLOUD_ROOT .. "/src/backend/coreaudio/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include"
		}
	end

	if (WITH_PORTAUDIO == 1) then
		defines {"WITH_PORTAUDIO"}

		files {
		  SOLOUD_ROOT .. "/src/backend/portaudio/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include",
		  portaudio_include
		}
	end

	if (WITH_SDL == 1) then
			defines { "WITH_SDL" }
		files {
		  SOLOUD_ROOT .. "/src/backend/sdl/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include",
		  sdl2_include
		}
	end

	if (WITH_SDL2 == 1) then
			defines { "WITH_SDL2" }
		files {
		  SOLOUD_ROOT .. "/src/backend/sdl/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include",
		  sdl2_include
		}
	end

	if (WITH_SDL_STATIC == 1) then
			defines { "WITH_SDL_STATIC" }
		files {
		  SOLOUD_ROOT .. "/src/backend/sdl_static/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include",
		  sdl_include
		}
	end

	if (WITH_SDL2_STATIC == 1) then
			defines { "WITH_SDL2_STATIC" }
		files {
		  SOLOUD_ROOT .. "/src/backend/sdl2_static/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include",
		  sdl2_include
		}
	end

	if (WITH_WASAPI == 1) then
			defines { "WITH_WASAPI" }
		files {
		  SOLOUD_ROOT .. "/src/backend/wasapi/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include"
		}
	end

	if (WITH_XAUDIO2 == 1) then
		defines {"WITH_XAUDIO2"}
		files {
		  SOLOUD_ROOT .. "/src/backend/xaudio2/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include",
		  dxsdk_include
		}
	end

	if (WITH_WINMM == 1) then
			defines { "WITH_WINMM" }
		files {
		  SOLOUD_ROOT .. "/src/backend/winmm/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include"
		}
	end

	if (WITH_VITA_HOMEBREW == 1) then
			defines { "WITH_VITA_HOMEBREW", "usleep=sceKernelDelayThread" }
		files {
		  SOLOUD_ROOT .. "/src/backend/vita_homebrew/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include"
		}
	end


	if (WITH_JACK == 1) then
		defines { "WITH_JACK" }
		links { "jack" }
		files {
		  SOLOUD_ROOT .. "/src/backend/jack/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include"
		}
	end

	if (WITH_NULL == 1) then
		defines { "WITH_NULL" }
		files {
		  SOLOUD_ROOT .. "/src/backend/null/**.c*"
		  }
		includedirs {
		  SOLOUD_ROOT .. "/include"
		}
	end    
end

function projectDependencies_soloud()
	return { "stb" }
end

function projectAdd_soloud()

	if getTargetOS() == "windows" then
		table.insert(SOLOUD_FILES, SOLOUD_ROOT .. "/src/backend/xaudio2/**.*")
	end

	if getTargetOS() == "asmjs" then
		table.insert(SOLOUD_FILES, SOLOUD_ROOT .. "/src/backend/miniaudio/**.*")
	end

	addProject_3rdParty_lib("soloud", SOLOUD_FILES)
end

function projectSource_soloud()
	return "https://github.com/jarikomppa/soloud"
end
