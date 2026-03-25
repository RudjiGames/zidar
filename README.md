![zidar logo](https://github.com/RudjiGames/imagus/blob/main/zidar/doc/zidar_logo.png)

[![License](https://img.shields.io/badge/license-BSD--2%20clause-blue.svg)](https://github.com/RudjiGames/zidar/blob/master/LICENSE)

**zidar** is a Lua based build system framework built on top of [**GENie**](https://github.com/bkaradzic/GENie) project generator. It minimizes the effort needed to maintain C/C++ project configurations and their physical organization on disk across different target platforms.

You describe your projects with minimal Lua — declare a project type and its dependencies — and **zidar** handles everything else: dependency resolution, compiler/linker flags, platform detection, project generation.

```lua
-- genie.lua
newoption { trigger = "zidar-path", description = "Path to zidar" }
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile("my_lib.lua")
dofile("my_game.lua")

solution "my_engine"
    setPlatforms()
    projectAdd("my_lib")      -- recursively resolves and adds all dependencies
    projectAdd("my_game")
```

```lua
-- my_lib.lua
function projectAdd_my_lib()
    addProject_lib("my_lib")
end

-- my_game.lua
function projectDependencies_my_game()
    return { "my_lib" }
end

function projectAdd_my_game()
    addProject_game("my_game")
end
```

## Features

- **Automatic dependency resolution** — recursively discovers, downloads (via git), and links project dependencies
- **Cross-platform** — Windows, Linux, macOS, iOS, tvOS, visionOS, Android, WebAssembly, FreeBSD, NetBSD, RISC-V, Raspberry Pi
- **Multiple toolchains** — Visual Studio 2017-2022, GCC, Clang, MinGW, Xcode, Android NDK, Emscripten
- **Console support** — PlayStation 4/5 (Orbis/Prospero), Xbox One (Durango), Nintendo Switch
- **Qt 6 integration** — automatic MOC, UIC, RCC, and translation file processing
- **Shader compilation** — bgfx shader cross-compilation (GLSL, SPIR-V, DirectX 9/11, Metal) as a pre-build step
- **Third-party library management** — build scripts for 60+ common libraries
- **Precompiled header support** — automatic PCH detection and configuration
- **Deployment** — platform-specific packaging, icon generation, and manifest creation

## Quick Start

**1.** Install [GENie](https://github.com/bkaradzic/GENie) and place it in your PATH

**2.** Create a project script (`scripts/my_app.lua`):

```lua
function projectAdd_my_app()
    addProject_cmd("my_app")
end
```

**3.** Create the entry point (`scripts/genie.lua`):

```lua
newoption { trigger = "zidar-path", description = "Path to zidar" }
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile("my_app.lua")

solution "my_app"
    setPlatforms()
    projectAdd("my_app")
```

**4.** Generate build files:

```bash
genie --zidar-path=/path/to/zidar vs2022     # Visual Studio 2022
genie --zidar-path=/path/to/zidar gmake      # GNU Makefiles
genie --zidar-path=/path/to/zidar ninja      # Ninja
genie --zidar-path=/path/to/zidar xcode9     # Xcode
```

## Convention-Based Project Layout

Each project follows a directory convention that zidar uses for auto-discovery:

```
project_name/
  scripts/
    genie.lua              -- standalone entry point
    project_name.lua       -- defines projectAdd_<name>(), projectDependencies_<name>(), etc.
  src/                     -- source files and private headers
  include/                 -- public headers (auto-added to dependents' include paths)
  tests/                   -- unit tests (added with --with-unittests)
  samples/                 -- sample projects (added with --with-samples)
  tools/                   -- tool projects (added with --with-tools)
  3rd/                     -- project-specific 3rd party code
```

## Project Types

| Type | Function | Output |
|---|---|---|
| Library | `addProject_lib` | Static or shared library |
| 3rd party lib | `addProject_3rdParty_lib` | Static library with relaxed warnings |
| Command tool | `addProject_cmd` | Console executable |
| Game | `addProject_game` | Windowed (retail) / console (debug) executable |
| Qt project | `addProject_qt` | Qt application or static library |
| Library tool | `addProject_lib_tool` | Tool executable (part of a library) |
| Library sample | `addProject_lib_sample` | Sample executable for a library |
| Library test | `addProject_lib_test` | Unit test executable |

## Callback System

Projects are defined through named callback functions. Zidar calls them automatically during dependency resolution and project generation:

| Callback | Purpose |
|---|---|
| `projectAdd_<name>()` | **Required.** Adds the project to the solution |
| `projectDependencies_<name>()` | Returns a table of dependency names |
| `projectSource_<name>()` | Returns a git URL for auto-download |
| `projectExtraConfig_<name>()` | Per-configuration extra flags/defines/links |
| `projectExtraConfigExecutable_<name>()` | Extra settings for executable targets |
| `projectDependencyConfig_<name>()` | Settings applied when used as a dependency |
| `projectDescription_<name>()` | Human-readable project description |
| `projectHeaderOnlyLib_<name>` | Set to skip linking (header-only library) |

## Build Configurations

| Configuration | Defines | Key Flags |
|---|---|---|
| `debug` | `RG_DEBUG_BUILD`, `_DEBUG` | Symbols |
| `release` | `RG_RELEASE_BUILD`, `NDEBUG` | OptimizeSpeed, Symbols |
| `retail` | `RG_RETAIL_BUILD`, `NDEBUG`, `RETAIL` | OptimizeSpeed, no symbols |

## Command Line Options

| Option | Description |
|---|---|
| `--zidar-path=PATH` | Path to the zidar directory (required) |
| `--with-unittests` | Generate library unit test projects |
| `--with-tools` | Generate library tool projects |
| `--with-samples` | Generate library sample projects |
| `--with-no-pch` | Disable precompiled headers |
| `--gcc=VARIANT` | GCC/Clang variant (linux-gcc, linux-clang, android-arm64, osx-arm64, wasm, ...) |
| `--vs=TOOLSET` | Visual Studio toolset (vs2017-clang, winstore100, durango, orbis, prospero) |
| `--xcode=TARGET` | Xcode target (osx, ios, tvos, xros) |
| `--with-android=LEVEL` | Android API level (default: 24) |
| `--with-ios=VERSION` | iOS minimum deployment target |
| `--with-macos=VERSION` | macOS minimum deployment target |
| `--with-dynamic-runtime` | Use dynamic runtime linking |
| `--with-avx` | Enable AVX instruction set |

## Third-Party Libraries

Zidar includes build scripts for 60+ libraries in `3rd/`. When a dependency isn't found locally, zidar automatically downloads it via `git clone`:

`assimp` `basis_universal` `bgfx` `bimg` `bnet` `box2d` `bx` `cgltf` `curl` `efsw` `enet` `enkiTS` `fcpp` `freetype2` `imgui` `jolt` `libdom` `libparserutils` `librdkafka` `libsvgtiny` `libtess2` `libuv` `libwapcaplet` `libxml2` `lua` `mbedtls` `meshoptimizer` `minilua` `msdf_atlas_gen` `msdfgen` `nanosvg` `nanovg` `ogg` `openssl` `raw_pdb` `sasl2` `simple-svg` `soloud` `sparsehash` `spdlog` `squish` `stb` `subprocess.h` `ta_lib` `tbb` `tinygltf` `tinyspline` `tinyxml2` `tomlplusplus` `ufbx` `unity` `unittest-cpp` `usockets` `uwebsockets` `vg_renderer` `vorbis` `wolfssl` `xxHash` `zfp` `zlib` `zstd`

## Samples

The `samples/` directory contains five progressively complex examples:

| Sample | Description |
|---|---|
| **01_hello_world** | Minimal console application |
| **02_hello_library** | Static library with tests and samples |
| **03_tool_using_a_library** | Command-line tool with a library dependency |
| **04_Qt_app_using_a_library** | Qt GUI application with a library dependency |
| **05_fancy_game_engine** | Multi-project setup: libraries, games, command-line and Qt tools |

Each sample includes a standalone `genie.lua` so it can be built independently.

## Script Overview

| Script | Purpose |
|---|---|
| `zidar.lua` | Main entry point — options, globals, dependency resolution, project loading |
| `toolchain.lua` | Compiler and linker flags per platform/architecture |
| `configurations.lua` | Per-project build configuration, vpath mapping, Qt/shader hooks |
| `project_lib.lua` | Library project setup (static and shared) |
| `project_3rd.lua` | Third-party library project setup |
| `project_cmdtool.lua` | Command-line tool project setup |
| `project_game.lua` | Game/application project setup |
| `project_lib_tool.lua` | Library tool sub-project setup |
| `project_lib_sample.lua` | Library sample sub-project setup |
| `project_lib_test.lua` | Library test sub-project setup |
| `project_qt.lua` | Qt application/library project setup |
| `qtpresets6.lua` | Qt 6 MOC/QRC/UI/translation processing |
| `qtprebuild.lua` | Qt pre-build file operations (standalone) |
| `embedded_files.lua` | Shader compilation pre-build step configuration |
| `embedded_shader_prebuild.lua` | Shader compilation script (standalone) |
| `deploy.lua` | Platform-specific deployment and packaging |
| `3rd/*.lua` | Individual build scripts for third-party libraries |

## Documentation

Full documentation is available in the [doc/](doc/) directory:

1. [Overview](doc/zidar_doc_01_overview.md) — architecture, conventions, and global variables
2. [Getting Started](doc/zidar_doc_02_getting_started.md) — setup, command line options, and environment
3. [Project Types](doc/zidar_doc_03_project_types.md) — all project types, callbacks, and dependency resolution
4. [Custom Configurations](doc/zidar_doc_04_custom_configurations.md) — toolchains, Qt, shaders, 3rd party management
5. [Samples](doc/zidar_doc_05_samples.md) — walkthrough of all included sample projects

## Dependencies

- [GENie](https://github.com/bkaradzic/GENie) — project file generator (required)
- [Lua](https://www.lua.org/) — required for Qt-based projects (used in prebuild steps)
- **Windows** users should install [GnuWin32 tools](https://github.com/Silvenga/GnuWin32-Installer) (`sed`, `make`)
- `git`, `make`, `ninja` — must be in PATH

## License (BSD 2-clause)

<a href="http://opensource.org/licenses/BSD-2-Clause" target="_blank">
<img align="right" src="https://opensource.org/wp-content/uploads/2022/10/osi-badge-dark.svg" width="100" height="137">
</a>

	Copyright 2025-2026 by Milos Tosic. All rights reserved.

	https://github.com/RudjiGames/zidar

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	   1. Redistributions of source code must retain the above copyright notice,
	      this list of conditions and the following disclaimer.

	   2. Redistributions in binary form must reproduce the above copyright
	      notice, this list of conditions and the following disclaimer in the
	      documentation and/or other materials provided with the distribution.

	THIS SOFTWARE IS PROVIDED BY COPYRIGHT HOLDER ``AS IS'' AND ANY EXPRESS OR
	IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
	EVENT SHALL COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
	THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
