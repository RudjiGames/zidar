# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Zidar is a Lua-based build system framework built on top of [GENie](https://github.com/bkaradzic/GENie) (a Premake fork). It generates build files for C/C++ projects across platforms — you describe projects with minimal Lua callbacks and zidar handles dependency resolution, compiler flags, and platform detection.

## Generating Build Files

Zidar does not compile code directly. It generates IDE/build system project files via GENie:

```bash
genie --zidar-path=/path/to/zidar vs2022     # Visual Studio 2022
genie --zidar-path=/path/to/zidar gmake      # GNU Makefiles
genie --zidar-path=/path/to/zidar ninja       # Ninja
genie --zidar-path=/path/to/zidar xcode9      # Xcode
```

Samples can be built standalone from their directories (each has its own `genie.lua`):
```bash
cd samples/01_hello_world/
make projgen
```

Key options: `--with-unittests`, `--with-tools`, `--with-samples`, `--with-no-pch`, `--gcc=VARIANT`, `--vs=TOOLSET`.

## Architecture

**Entry point**: `zidar.lua` — loaded via `dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")` from a project's `genie.lua`. It bootstraps the entire framework by loading all other scripts.

**Core scripts and their roles:**

| Script | Role |
|---|---|
| `zidar.lua` | Options, globals, dependency resolution, project loading, path caching |
| `toolchain.lua` | Compiler/linker flags for 30+ platform/compiler combinations |
| `configurations.lua` | Per-project build config (debug/release/retail), vpath mapping |
| `deploy.lua` | Platform-specific packaging, manifest generation, icon conversion |
| `qtpresets6.lua` | Qt 6 MOC/UIC/RCC/translation processing |
| `qtprebuild.lua` | Standalone Qt tool executor (called as prebuild step) |
| `embedded_files.lua` / `embedded_shader_prebuild.lua` | bgfx shader cross-compilation |
| `project_*.lua` | Project type handlers (lib, cmd, game, qt, 3rd, test, sample, tool) |
| `3rd/*.lua` | Build scripts for 60+ third-party libraries |

**Dependency resolution flow**: `projectAdd(name)` → looks up `projectDependencies_<name>()` → recursively loads and adds all deps → calls `projectAdd_<name>()` which invokes the appropriate `addProject_*()` function.

**Project callback convention**: Projects are defined by registering global Lua functions named `project<Callback>_<projectname>()`. The required one is `projectAdd_<name>()`. Optional callbacks: `projectDependencies_`, `projectSource_`, `projectExtraConfig_`, `projectExtraConfigExecutable_`, `projectDependencyConfig_`, `projectDescription_`. A global variable `projectHeaderOnlyLib_<name>` marks header-only libraries.

**Convention-based directory layout** expected per project:
```
project_name/
  scripts/       -- genie.lua + project_name.lua
  src/           -- source files and private headers
  include/       -- public headers (auto-added to dependents)
  tests/         -- unit tests (--with-unittests)
  samples/       -- samples (--with-samples)
  tools/         -- tools (--with-tools)
```

## Build Configurations

Three configurations: `debug` (`RG_DEBUG_BUILD`), `release` (`RG_RELEASE_BUILD`, optimized with symbols), `retail` (`RG_RETAIL_BUILD`, fully optimized, no symbols).

## Lua Coding Conventions

- Tab indentation
- Function names use camelCase with underscores for project callbacks (e.g., `projectSourceFilesWildcard`)
- Internal/private functions prefixed with underscore (e.g., `_runExitCallbacks()`)
- Global cache tables prefixed with `g_` (e.g., `g_projectPathCache`, `g_resolvedDependencies`)
- Table-based enums (e.g., `Color`, `LibraryType`)
- Section dividers with dashes in comments
- Copyright header on all files

## Key Global Variables

- `ZIDAR_DIR_PATH` — path to zidar installation
- `ZIDAR_SOLUTION_NAME` — current solution name
- `ZIDAR_PROJECT_DIR` — current project working directory
- `ZIDAR_PROJECTS_DIR_LIST` — list of directories to search for projects

## Third-Party Library Scripts

Each `3rd/*.lua` file defines how to build a specific library. They use `addProject_3rdParty_lib()` and define source files, include paths, platform-specific flags, and a `projectSource_<name>()` returning the git clone URL. Missing dependencies are auto-downloaded via git.

## Prerequisites

- [GENie](https://github.com/bkaradzic/GENie) in PATH
- `git`, `make`/`ninja` in PATH
- Windows: [GnuWin32 tools](https://github.com/Silvenga/GnuWin32-Installer) for `sed`, `make`
- Qt projects: `QTDIR` environment variable pointing to Qt 6 installation
- Lua interpreter required for Qt prebuild steps
