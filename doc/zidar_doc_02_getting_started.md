# Zidar - Getting Started

This guide walks you through setting up new projects with zidar, from the simplest "Hello World" console application to multi-project solutions with libraries, dependencies, tests, and Qt integration.

## Prerequisites

Before starting, ensure you have:

- [GENie](https://github.com/bkaradzic/GENie) build system generator in your `PATH`
- `git` installed (for downloading 3rd party dependencies)
- A C/C++ compiler:
  - **Windows**: Visual Studio 2017 or later, or MinGW
  - **Linux**: GCC or Clang
  - **macOS**: Xcode with command-line tools
- `make` or `ninja` for building (unless using Visual Studio / Xcode IDE)
- **Windows only**: [GnuWin32](https://github.com/Silvenga/GnuWin32-Installer) for `sed` and `make`
- **Qt projects only**: Qt 6 installed with `QTDIR` environment variable set

## Tutorial 1: Hello World (Console Application)

The simplest possible zidar project — a command-line tool that prints a message.

### Project Structure

```
my_hello_world/
├── scripts/
│   ├── genie.lua              -- entry point for GENie
│   └── my_hello_world.lua     -- project definition
└── src/
    └── main.c                 -- source code
```

### Step 1: Create the Directory Structure

Create the project root and subdirectories:

```bash
mkdir -p my_hello_world/scripts
mkdir -p my_hello_world/src
```

### Step 2: Write the Source Code

Create `my_hello_world/src/main.c`:

```c
#include <stdio.h>

int main()
{
    printf("Hello, zidar!\n");
    return 0;
}
```

Zidar automatically discovers all `.c`, `.cpp`, `.h`, and `.hpp` files inside `src/`. You never need to list individual files — just put them in the right directory.

### Step 3: Create the Project Script

Create `my_hello_world/scripts/my_hello_world.lua`:

```lua
function projectAdd_my_hello_world()
    addProject_cmd("my_hello_world")
end
```

This registers a single callback function that tells zidar how to add the project. `addProject_cmd()` creates a console application — it looks for source files in the project's root directory and produces an executable.

**Key concept**: Zidar identifies projects by name. The function name must follow the pattern `projectAdd_<name>()` where `<name>` matches the project name with dashes and dots replaced by underscores.

### Step 4: Create the Entry Point

Create `my_hello_world/scripts/genie.lua`:

```lua
newoption { trigger = "zidar-path", description = "Path to zidar" }
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile("my_hello_world.lua")

solution "my_hello_world"
    setPlatforms()
    projectAdd("my_hello_world")
```

This file is what GENie executes. It does four things:

1. **Declares the `--zidar-path` option** so you can tell GENie where zidar is installed
2. **Loads zidar** which initializes the entire framework (globals, toolchain, project types, 3rd party registry)
3. **Loads your project script** which registers the `projectAdd_my_hello_world()` callback
4. **Creates a solution** (the top-level container for all projects), configures platforms, and adds the project

### Step 5: Generate Build Files

From the `my_hello_world/scripts/` directory, run GENie with the desired build system:

```bash
# Visual Studio 2022 (Windows)
genie --zidar-path=/path/to/zidar vs2022

# GNU Makefiles with GCC (Linux)
genie --zidar-path=/path/to/zidar --gcc=linux-gcc gmake

# GNU Makefiles with Clang (Linux)
genie --zidar-path=/path/to/zidar --gcc=linux-clang gmake

# Xcode (macOS)
genie --zidar-path=/path/to/zidar --xcode=osx xcode9

# Ninja build files
genie --zidar-path=/path/to/zidar ninja
```

GENie generates native project files in a `.zidar/` directory. For Visual Studio, this produces a `.sln` file you can open directly. For Makefiles, you then run `make` to build.

### Step 6: Build

```bash
# Makefiles
make -C .zidar/projects/gmake-linux-clang config=debug64
make -C .zidar/projects/gmake-linux-clang config=release64

# Ninja
ninja -C .zidar/projects/ninja-linux-clang config=debug64

# Visual Studio: open .zidar/projects/vs2022/my_hello_world.sln
```

Output binaries are placed in `.zidar/` with a configuration suffix (e.g. `my_hello_world_debug`, `my_hello_world_release`).

### Optional: Create a Makefile

To avoid typing long GENie commands, create a `my_hello_world/makefile`:

```makefile
RG_ZIDAR_DIR?=/path/to/zidar
GENIE?=$(RG_ZIDAR_DIR)/tools/bin/$(OS)/genie --zidar-path=$(RG_ZIDAR_DIR)

projgen: ## Generate project files for all configurations.
	$(GENIE) vs2022
	$(GENIE) --gcc=linux-clang gmake
	$(GENIE) --gcc=linux-gcc gmake
	$(GENIE) --gcc=osx-arm64 gmake
	$(GENIE) --xcode=osx xcode9

clean:
	$(GENIE) clean
```

Then simply run `make projgen` to generate all build variants at once.

---

## Tutorial 2: Creating a Library

Libraries are the building blocks of zidar projects. A library has public headers (in `include/`) that dependents can use and source files (in `src/`) that implement the functionality.

### Project Structure

```
my_math_lib/
├── scripts/
│   ├── genie.lua
│   └── my_math_lib.lua
├── include/
│   └── my_math_lib.h         -- public header (auto-added to dependents' include paths)
├── src/
│   └── my_math_lib.c         -- implementation
└── tests/
    └── my_math_lib_test.c    -- unit tests (optional)
```

### Step 1: Write the Library Code

Create `my_math_lib/include/my_math_lib.h`:

```c
#ifndef MY_MATH_LIB_H
#define MY_MATH_LIB_H

int myMathAdd(int a, int b);
int myMathMultiply(int a, int b);

#endif
```

Create `my_math_lib/src/my_math_lib.c`:

```c
#include "my_math_lib.h"

int myMathAdd(int a, int b)
{
    return a + b;
}

int myMathMultiply(int a, int b)
{
    return a * b;
}
```

**Convention**: The `include/` directory contains public headers. When another project depends on your library, zidar automatically adds your `include/` directory to its include paths. The `src/` directory contains implementation files and private headers.

### Step 2: Create the Project Script

Create `my_math_lib/scripts/my_math_lib.lua`:

```lua
function projectAdd_my_math_lib()
    addProject_lib("my_math_lib")
end
```

`addProject_lib()` creates a static library by default. It:
- Searches `src/` and `include/` for source files
- Auto-detects whether the project is C or C++ based on file extensions
- Configures precompiled headers if found
- Handles platform-specific files (e.g. Objective-C++ `.mm` files on Apple platforms)

### Step 3: Create the Entry Point

Create `my_math_lib/scripts/genie.lua`:

```lua
newoption { trigger = "zidar-path", description = "Path to zidar" }
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile("my_math_lib.lua")

solution "my_math_lib"
    setPlatforms()
    addLibProjects("my_math_lib")
```

Note the use of `addLibProjects()` instead of `projectAdd()`. This function is designed for libraries and automatically handles sub-projects:
- If `--with-unittests` is passed: discovers and adds test projects from `tests/`, named `<lib>_test`
- If `--with-samples` is passed: discovers and adds sample projects from `samples/`, named `<lib>_<sampledir>`
- If `--with-tools` is passed: discovers and adds tool projects from `tools/`, named `<lib>_<tooldir>`

### Step 4: Add Unit Tests (Optional)

Create `my_math_lib/tests/my_math_lib_test.c`:

```c
#include "my_math_lib.h"
#include <rg_core/rg_test.h>

TEST(MyMathLib, Add)
{
    CHECK_EQUAL(5, myMathAdd(2, 3));
    CHECK_EQUAL(0, myMathAdd(-1, 1));
}

TEST(MyMathLib, Multiply)
{
    CHECK_EQUAL(6, myMathMultiply(2, 3));
    CHECK_EQUAL(0, myMathMultiply(0, 5));
}
```

Zidar automatically selects the test framework based on language:
- **C++ projects** link to `unittest-cpp`
- **C projects** link to the `unity` test framework

The test project is named `my_math_lib_test` and placed in the `tests` IDE group.

Generate build files with tests enabled:

```bash
genie --zidar-path=/path/to/zidar --with-unittests vs2022
```

---

## Tutorial 3: Tool with Library Dependencies

Most real projects depend on libraries. Zidar resolves dependencies recursively — you just declare what you need.

### Project Structure

```
my_calculator/
├── scripts/
│   ├── genie.lua
│   └── my_calculator.lua
└── src/
    └── calculator.c
```

### Step 1: Write the Tool

Create `my_calculator/src/calculator.c`:

```c
#include <stdio.h>
#include "my_math_lib.h"

int main()
{
    int result = myMathAdd(10, 20);
    printf("10 + 20 = %d\n", result);

    result = myMathMultiply(5, 6);
    printf("5 * 6 = %d\n", result);

    return 0;
}
```

Notice that you `#include "my_math_lib.h"` directly — zidar will add the library's `include/` directory to your include paths automatically.

### Step 2: Declare Dependencies

Create `my_calculator/scripts/my_calculator.lua`:

```lua
function projectDependencies_my_calculator()
    return { "my_math_lib" }
end

function projectAdd_my_calculator()
    addProject_cmd("my_calculator")
end
```

The `projectDependencies_<name>()` callback returns a table listing the project names this project depends on. Zidar will:

1. Locate `my_math_lib` by searching the directory tree (or the 3rd party registry)
2. Load its script and resolve its own dependencies recursively
3. Add include paths from `my_math_lib/include/` to the calculator's configuration
4. Link the `my_math_lib` static library into the calculator executable
5. Ensure `my_math_lib` is built before `my_calculator`

### Step 3: Create the Entry Point

Create `my_calculator/scripts/genie.lua`:

```lua
newoption { trigger = "zidar-path", description = "Path to zidar" }
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile("my_calculator.lua")

solution "my_calculator"
    setPlatforms()
    projectAdd("my_calculator")
```

You only need to call `projectAdd()` for the calculator — zidar automatically adds `my_math_lib` (and any of its transitive dependencies) to the solution.

### How Dependency Resolution Works

When zidar processes `projectAdd("my_calculator")`:

1. Calls `projectDependencies_my_calculator()` → gets `{ "my_math_lib" }`
2. Searches for `my_math_lib`'s directory (checks cache, then walks up parent directories searching up to 3 subdirectory levels deep at each step, then 3rd party registry)
3. Loads `my_math_lib.lua` if not already loaded
4. Calls `projectDependencies_my_math_lib()` to get its dependencies (recursing further if needed)
5. Flattens all transitive dependencies into a single deduplicated list
6. For GNU Make, sorts by dependency depth (deepest-first) for correct link order
7. Caches the result in `g_resolvedDependencies` so subsequent lookups are instant
8. Creates the `my_math_lib` project in the solution, then creates `my_calculator` with proper include paths and link settings

---

## Tutorial 4: Multi-Project Solution

For larger codebases, you typically have multiple libraries, tools, and applications in a single solution. This is how real game engines and frameworks are structured.

### Project Structure

```
my_engine/
├── scripts/
│   └── genie.lua                      -- top-level entry point
├── src/
│   ├── libraries/
│   │   ├── libraries.lua              -- loads all library scripts
│   │   ├── core/
│   │   │   ├── include/core.h
│   │   │   ├── src/core.c
│   │   │   └── scripts/core.lua
│   │   └── renderer/
│   │       ├── include/renderer.h
│   │       ├── src/renderer.cpp
│   │       └── scripts/renderer.lua
│   ├── tools/
│   │   ├── tools.lua                  -- loads all tool scripts
│   │   └── asset_converter/
│   │       ├── src/asset_converter.c
│   │       └── scripts/asset_converter.lua
│   └── games/
│       ├── games.lua                  -- loads all game scripts
│       └── my_game/
│           ├── src/my_game.c
│           └── scripts/my_game.lua
```

### Library Scripts

Create `src/libraries/core/scripts/core.lua`:

```lua
function projectAdd_core()
    addProject_lib("core")
end
```

Create `src/libraries/renderer/scripts/renderer.lua`:

```lua
function projectDependencies_renderer()
    return { "core" }
end

function projectAdd_renderer()
    addProject_lib("renderer")
end
```

### Loader Scripts

Create `src/libraries/libraries.lua`:

```lua
dofile "../src/libraries/core/scripts/core.lua"
dofile "../src/libraries/renderer/scripts/renderer.lua"
```

Create `src/tools/tools.lua`:

```lua
dofile "../src/tools/asset_converter/scripts/asset_converter.lua"
```

Create `src/games/games.lua`:

```lua
dofile "../src/games/my_game/scripts/my_game.lua"
```

### Tool and Game Scripts

Create `src/tools/asset_converter/scripts/asset_converter.lua`:

```lua
function projectDependencies_asset_converter()
    return { "core" }
end

function projectAdd_asset_converter()
    addProject_cmd("asset_converter")
end
```

Create `src/games/my_game/scripts/my_game.lua`:

```lua
function projectDependencies_my_game()
    return { "renderer", "core" }
end

function projectAdd_my_game()
    addProject_game("my_game")
end
```

Note: `addProject_game()` produces a windowed application in retail builds and a console application in debug/release (so you get a console window for debug output during development).

### Top-Level Entry Point

Create `scripts/genie.lua`:

```lua
newoption { trigger = "zidar-path", description = "Path to zidar" }
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile "../src/libraries/libraries.lua"
dofile "../src/tools/tools.lua"
dofile "../src/games/games.lua"

solution "my_engine"
    setPlatforms()
    projectAdd("core")
    projectAdd("renderer")
    projectAdd("asset_converter")
    projectAdd("my_game")
```

All projects appear in the same solution, organized into IDE groups: `libs` for libraries, `tools_cmd` for command-line tools, and `games` for game projects.

---

## Tutorial 5: Qt Application

Zidar has first-class Qt 6 support with automatic MOC, UIC, RCC, and translation file processing.

### Prerequisites

- Qt 6 installed
- `QTDIR` environment variable pointing to your Qt installation (e.g. `C:\Qt\6.5.0\msvc2019_64`)
- Lua interpreter in your `PATH` (required for Qt prebuild steps)

### Project Structure

```
my_qt_app/
├── scripts/
│   ├── genie.lua
│   └── my_qt_app.lua
└── src/
    ├── main.cpp              -- application entry point
    ├── main_window.h         -- QMainWindow subclass (processed by MOC)
    ├── main_window.cpp       -- implementation
    ├── main_window.ui        -- Qt Designer form (optional, processed by UIC)
    ├── resources.qrc         -- Qt resource file (optional, processed by RCC)
    └── translations/
        └── app_en.ts         -- translation file (optional, processed by lrelease)
```

### Step 1: Write the Application

Create `my_qt_app/src/main_window.h`:

```cpp
#pragma once

#include <QMainWindow>

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget* parent = nullptr);

private slots:
    void onButtonClicked();
};
```

Create `my_qt_app/src/main_window.cpp`:

```cpp
#include "main_window.h"
#include <QPushButton>
#include <QVBoxLayout>
#include <QMessageBox>

MainWindow::MainWindow(QWidget* parent)
    : QMainWindow(parent)
{
    QWidget* central = new QWidget(this);
    QVBoxLayout* layout = new QVBoxLayout(central);

    QPushButton* button = new QPushButton("Click me!", central);
    layout->addWidget(button);
    connect(button, &QPushButton::clicked, this, &MainWindow::onButtonClicked);

    setCentralWidget(central);
    setWindowTitle("My Qt App");
    resize(400, 300);
}

void MainWindow::onButtonClicked()
{
    QMessageBox::information(this, "Hello", "Hello from zidar + Qt!");
}
```

Create `my_qt_app/src/main.cpp`:

```cpp
#include <QApplication>
#include "main_window.h"

int main(int argc, char* argv[])
{
    QApplication app(argc, argv);
    MainWindow window;
    window.show();
    return app.exec();
}
```

### Step 2: Create the Project Script

Create `my_qt_app/scripts/my_qt_app.lua`:

```lua
function projectAdd_my_qt_app()
    addProject_qt("my_qt_app")
end
```

`addProject_qt()` automatically:
- Sets the language to C++
- Produces a windowed application (no console window)
- Discovers `.ui`, `.qrc`, and `.ts` files in `src/`
- Generates MOC prebuild commands for headers containing `Q_OBJECT`
- Links Qt modules: Core, Gui, Widgets, and Network by default

To link additional Qt modules, pass them as the last argument:

```lua
function projectAdd_my_qt_app()
    addProject_qt("my_qt_app", nil, nil, nil, { "Sql", "Xml", "WebEngineWidgets" })
end
```

### Step 3: Create the Entry Point and Generate

Create `my_qt_app/scripts/genie.lua`:

```lua
newoption { trigger = "zidar-path", description = "Path to zidar" }
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile("my_qt_app.lua")

solution "my_qt_app"
    setPlatforms()
    projectAdd("my_qt_app")
```

Generate and build:

```bash
genie --zidar-path=/path/to/zidar vs2022
```

### Qt with Library Dependencies

Qt apps can depend on your own libraries just like any other project:

```lua
function projectDependencies_my_qt_app()
    return { "my_math_lib" }
end

function projectAdd_my_qt_app()
    addProject_qt("my_qt_app")
end
```

---

## Tutorial 6: Using 3rd Party Libraries

Zidar ships with 63 pre-configured build scripts for popular C/C++ libraries. When you declare a dependency on one of these, zidar automatically downloads the source code via git and builds it as part of your project.

### Using a Built-In 3rd Party Library

Simply list the library name in your dependencies:

```lua
function projectDependencies_my_project()
    return { "zlib", "imgui", "spdlog" }
end

function projectAdd_my_project()
    addProject_cmd("my_project")
end
```

When you generate build files, zidar will:

1. Recognize `zlib`, `imgui`, and `spdlog` from its 3rd party registry
2. Clone the source code into the `.3rd/` directory (if not already present)
3. Create library projects for each dependency in the `3rd` IDE group
4. Add include paths and link settings to your project

No manual downloading, no submodules, no CMake — just declare the dependency.

### Available 3rd Party Libraries

Some commonly used libraries from the 63 included scripts:

| Category | Libraries |
|---|---|
| **Graphics** | bgfx, bimg, bx, imgui, nanosvg, nanovg |
| **3D/Mesh** | assimp, cgltf, tinygltf, ufbx, meshoptimizer |
| **Compression** | zlib, zstd, basis_universal |
| **Audio** | ogg, vorbis |
| **Networking** | curl, usockets, uwebsockets, librdkafka |
| **Physics** | box2d, jolt |
| **Cryptography** | mbedtls, openssl, wolfssl |
| **Scripting** | lua, minilua |
| **Utilities** | spdlog, enkiTS, tbb, tomlplusplus, xxHash |
| **Testing** | unittest-cpp, unity |

### How Auto-Download Works

Each 3rd party library defines a `projectSource_<name>()` callback returning a git URL:

```lua
function projectSource_zlib()
    return "https://github.com/madler/zlib.git"
end
```

When zidar cannot find a library locally and this callback exists, it runs `git clone` into the `.3rd/` directory automatically. On subsequent runs, the cached clone is reused.

---

## Project Callback Reference

Every project is defined by registering global Lua functions. Below is a summary of all available callbacks and when to use them.

### Required

| Callback | Purpose |
|---|---|
| `projectAdd_<name>()` | Creates the project by calling the appropriate `addProject_*()` function |

### Optional

| Callback | Purpose |
|---|---|
| `projectDependencies_<name>()` | Returns a table of dependency project names |
| `projectSource_<name>()` | Returns a git URL for auto-downloading (3rd party libraries) |
| `projectExtraConfig_<name>()` | Adds per-configuration flags, defines, or include paths |
| `projectExtraConfigExecutable_<name>()` | Same as above but only for executable targets linking this library |
| `projectDependencyConfig_<name>()` | Configuration applied to all projects that depend on this one |
| `projectDescription_<name>()` | Returns a human-readable description string |

### Special Variable

| Variable | Purpose |
|---|---|
| `projectHeaderOnlyLib_<name> = true` | Marks a header-only library (no linking, only include paths) |

### Naming Rules

- Project names may contain letters, numbers, dashes (`-`), and dots (`.`)
- In callback function names, dashes and dots are replaced with underscores
- Example: project `rg-core.lib` → functions named `projectAdd_rg_core_lib()`, etc.

---

## Project Type Reference

| Function | Kind | IDE Group | Use For |
|---|---|---|---|
| `addProject_cmd(name)` | ConsoleApp | `tools_cmd` | Command-line tools and utilities |
| `addProject_lib(name)` | StaticLib | `libs` | Reusable static/shared libraries |
| `addProject_game(name)` | ConsoleApp / WindowedApp | `games` | Game executables (windowed in retail) |
| `addProject_qt(name)` | WindowedApp | `tools` | Qt 6 GUI applications |
| `addProject_3rdParty_lib(name, files)` | StaticLib | `3rd` | External library wrappers |
| `addProject_lib_test(name)` | ConsoleApp | `tests` | Unit test executables |
| `addProject_lib_sample(name, sampleName)` | ConsoleApp | `samples` | Sample/demo executables named `<lib>_<sample>` |
| `addProject_lib_tool(name, libName)` | ConsoleApp | `libs-tools` | Library-related tools named `<lib>_<tool>` |

---

## Command Line Options

### Core Options

| Option | Description |
|---|---|
| `--zidar-path=PATH` | Path to the zidar directory (required) |
| `--with-unittests` | Generate unit test projects for libraries |
| `--with-tools` | Generate tool projects for libraries |
| `--with-samples` | Generate sample projects for libraries |
| `--with-no-pch` | Disable precompiled headers for all projects |

### Toolchain Options

| Option | Description |
|---|---|
| `--gcc=VARIANT` | GCC/Clang compiler variant (see below) |
| `--vs=TOOLSET` | Visual Studio toolset variant |
| `--xcode=TARGET` | Xcode target platform |
| `--with-android=LEVEL` | Android API level (default: 24) |
| `--with-ios=VERSION` | iOS minimum deployment target (default: 13.0) |
| `--with-macos=VERSION` | macOS minimum deployment target (default: 13.0) |
| `--with-tvos=VERSION` | tvOS minimum deployment target (default: 13.0) |
| `--with-visionos=VERSION` | visionOS minimum deployment target (default: 1.0) |
| `--with-windows=VERSION` | Windows SDK version |
| `--with-dynamic-runtime` | Use dynamic runtime linking |
| `--with-32bit-compiler` | Use 32-bit compiler |
| `--with-avx` | Enable AVX instruction set |
| `--with-glfw` | Link GLFW libraries |
| `--with-remove-crt` | Remove CRT from linking |

### GCC Variants

| Variant | Platform |
|---|---|
| `linux-gcc` | Linux with GCC |
| `linux-clang` | Linux with Clang |
| `linux-gcc-afl` | Linux with GCC + AFL fuzzer |
| `linux-clang-afl` | Linux with Clang + AFL fuzzer |
| `linux-arm-gcc` | Linux ARM with GCC |
| `linux-ppc64le-gcc` | Linux PPC64LE with GCC |
| `linux-ppc64le-clang` | Linux PPC64LE with Clang |
| `linux-riscv64-gcc` | Linux RISC-V 64 with GCC |
| `android-arm` | Android ARM |
| `android-arm64` | Android ARM64 |
| `android-x86` | Android x86 |
| `android-x86_64` | Android x86_64 |
| `ios-arm` | iOS ARM |
| `ios-arm64` | iOS ARM64 |
| `ios-simulator` | iOS Simulator |
| `tvos-arm64` | tvOS ARM64 |
| `tvos-simulator` | tvOS Simulator |
| `xros-arm64` | visionOS ARM64 |
| `xros-simulator` | visionOS Simulator |
| `osx-x64` | macOS x64 |
| `osx-arm64` | macOS ARM64 (Apple Silicon) |
| `mingw-gcc` | MinGW with GCC |
| `mingw-clang` | MinGW with Clang |
| `wasm` | WebAssembly (Emscripten) |
| `wasm2js` | WebAssembly to JS (Emscripten) |
| `orbis` | PlayStation 4 |
| `prospero` | PlayStation 5 |
| `rpi` | Raspberry Pi |
| `riscv` | RISC-V |
| `freebsd` | FreeBSD |
| `netbsd` | NetBSD |

### Visual Studio Toolsets

| Toolset | Description |
|---|---|
| `vs2017-clang` | Clang with MS CodeGen |
| `vs2017-xp` | VS 2017 targeting Windows XP |
| `winstore100` | Universal Windows App 10.0 |
| `durango` | Xbox One |
| `orbis` | PlayStation 4 |
| `prospero` | PlayStation 5 |

### Xcode Targets

| Target | Platform |
|---|---|
| `osx` | macOS |
| `ios` | iOS |
| `tvos` | tvOS |
| `xros` | visionOS |

---

## Build Configurations

Zidar defines three build configurations:

| Configuration | Defines | Flags | Use For |
|---|---|---|---|
| `debug` | `RG_DEBUG_BUILD`, `_DEBUG`, `DEBUG` | Symbols | Development and debugging |
| `release` | `RG_RELEASE_BUILD`, `NDEBUG` | OptimizeSpeed, NoFramePointer, NoBufferSecurityCheck, Symbols | Performance testing with debug symbols |
| `retail` | `RG_RETAIL_BUILD`, `NDEBUG`, `RETAIL` | OptimizeSpeed, NoFramePointer, NoBufferSecurityCheck | Final shipping builds |

Output binaries are suffixed with the configuration name (e.g. `mylib_debug.lib`, `mylib_release.lib`).

You can use these defines in your code to conditionally compile:

```c
#if defined(RG_DEBUG_BUILD)
    printf("Debug mode: extra logging enabled\n");
#endif
```

---

## Precompiled Headers

Zidar automatically detects and configures precompiled headers. For a project named `my_project`, place these files in the `src/` directory:

- `my_project_pch.h` — PCH header (required)
- `my_project_pch.cpp` or `my_project_pch.c` — PCH source (required)

Zidar checks for these files by name convention and enables PCH automatically. No configuration needed.

PCH is disabled on macOS/Xcode and can be globally disabled with `--with-no-pch`.

---

## Cleaning

```bash
genie --zidar-path=/path/to/zidar clean
```

This removes:
- The `.zidar/` build directory (generated project files and intermediates)
- The `.3rd/` dependency directory (cloned 3rd party sources)

The `.3rd/` directory is preserved if the `RG_ZIDAR_DEPENDENCY_DIR` environment variable is set to a custom location.

---

## Environment Variables

| Variable | Description |
|---|---|
| `QTDIR` | Qt 6 root directory (required for Qt projects) |
| `RG_ZIDAR_DEPENDENCY_DIR` | Override the default `.3rd/` dependency directory location |
| `HOME` / `HOMEPATH` | User home directory (used as a search boundary for project discovery) |
| `PATH` | Must contain GENie, git, and build tools |
| `WindowsSDKVersion` | Windows SDK version (auto-detected from Visual Studio environment) |

---

## Included Samples

Zidar ships with five progressively complex sample projects in the `samples/` directory:

| Sample | What It Demonstrates |
|---|---|
| `01_hello_world` | Minimal console application — the simplest possible zidar project |
| `02_hello_library` | Static library with public headers and unit tests |
| `03_tool_using_a_library` | Console tool with a library dependency — demonstrates dependency resolution |
| `04_Qt_app_using_a_library` | Qt 6 GUI application that depends on a library |
| `05_fancy_game_engine` | Multi-project solution with libraries, tools, Qt apps, and games |

Each sample is self-contained and can be built standalone:

```bash
cd samples/01_hello_world/
make projgen    # Generate build files for all platforms
```

These samples are the best reference for understanding zidar conventions in practice.
