# Zidar - Samples

This document walks through the five included sample projects in detail. Each sample builds on concepts from the previous one, progressing from a minimal "Hello World" to a full multi-project game engine setup. Together they demonstrate every major zidar feature: project types, dependency resolution, library conventions, unit testing, Qt integration, and multi-project solutions.

All samples are self-contained and can be built independently. They share a common makefile structure that generates project files for seven platform/compiler combinations at once.

---

## Building the Samples

Each sample directory contains a `makefile` that wraps GENie invocations. The standard workflow:

```bash
cd samples/01_hello_world/
make projgen    # Generate project files for all platforms
```

The `projgen` target generates projects for:

| Target | Generator | Platform |
|---|---|---|
| `vs2022` | Visual Studio 2022 | Windows (MSVC) |
| `--gcc=linux-clang gmake` | GNU Makefiles | Linux (Clang) |
| `--gcc=linux-gcc gmake` | GNU Makefiles | Linux (GCC) |
| `--gcc=osx-arm64 gmake` | GNU Makefiles | macOS (Apple Silicon) |
| `--xcode=osx xcode9` | Xcode project | macOS |
| `--xcode=ios xcode9` | Xcode project | iOS |
| `--gcc=android-arm64 gmake` | GNU Makefiles | Android (ARM64) |

All samples pass `--with-samples --with-unittests --with-tools` to enable sub-project generation where applicable.

To generate and build all samples at once from the top-level `samples/` directory:

```bash
cd samples/
make projgen    # Generate projects for all samples
```

---

## Sample 01: Hello World

**Purpose**: The absolute minimum zidar project. Demonstrates the basic three-file setup required for any zidar project: an entry point (`genie.lua`), a project script, and a source file.

**What it teaches**:
- How to structure a zidar project directory
- The `genie.lua` entry point pattern (option declaration, zidar loading, project script loading, solution creation)
- Using `addProject_cmd()` to create a console application
- How zidar auto-discovers source files from the `src/` directory
- How zidar auto-detects the language (C vs C++) from file extensions

### Directory Structure

```
01_hello_world/
├── makefile
├── scripts/
│   ├── genie.lua              -- GENie entry point
│   └── 01_hello_world.lua     -- project definition
└── src/
    └── hello_world.c          -- application source
```

### scripts/genie.lua

```lua
newoption { trigger = "zidar-path", description = "Path to zidar" }
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile("01_hello_world.lua")

solution "hello_world"
    setPlatforms()
    projectAdd("01_hello_world")
```

This is the standard zidar entry point. Every `genie.lua` follows this pattern:

1. **Declare the `--zidar-path` option** — tells GENie to accept the path to zidar as a command-line argument
2. **Load zidar** — `dofile` executes `zidar.lua`, which initializes all globals, loads all sub-scripts (toolchain, project types, 3rd party registry), and sets up the framework
3. **Load project scripts** — `dofile("01_hello_world.lua")` registers the project's callback functions into the global scope
4. **Create a solution** — `solution "hello_world"` creates a top-level container (Visual Studio solution, Xcode workspace, etc.)
5. **Configure platforms** — `setPlatforms()` sets up architectures and build configurations (debug/release/retail) based on the target build system
6. **Add projects** — `projectAdd("01_hello_world")` invokes the registered callback to create the project

### scripts/01_hello_world.lua

```lua
function projectAdd_01_hello_world()
    addProject_cmd("01_hello_world")
end
```

This is the simplest possible project script — a single callback function. When `projectAdd("01_hello_world")` is called from `genie.lua`, zidar looks up the global function `projectAdd_01_hello_world()` and calls it.

`addProject_cmd()` creates a `ConsoleApp` project. Internally, it:

1. Creates a project in the `tools_cmd` IDE group
2. Calls `projectGetPath("01_hello_world")` to locate the project directory
3. Calls `projectSourceFilesWildcard()` to generate glob patterns matching all `.c`, `.cpp`, `.h`, `.hpp`, `.inl` files in the project directory
4. Calls `projectIsCPP()` to check file extensions — since the only source file is `.c`, the language is set to C
5. Applies standard build flags and configurations
6. Resolves dependencies (none in this case)

### src/hello_world.c

```c
#include <stdio.h>

int main(int argc, char* argv[])
{
    (void)argc;
    (void)argv;

    printf("Hello world!\n");

    return 0;
}
```

A standard C program. Note that the filename does not need to match the project name — zidar discovers all source files in the directory via wildcard matching, regardless of name.

### What Happens at Generation Time

```
genie --zidar-path=../../ vs2022
```

1. GENie loads `scripts/genie.lua` as its entry point
2. Zidar initializes: displays a colored banner, sets up globals, loads toolchain and project type scripts
3. `01_hello_world.lua` is loaded, registering `projectAdd_01_hello_world()` in the global scope
4. A Visual Studio solution named `hello_world` is created
5. `setPlatforms()` configures x32/x64 architectures with debug/release/retail configurations
6. `projectAdd("01_hello_world")` calls the registered callback
7. `addProject_cmd()` creates a ConsoleApp project, discovers `src/hello_world.c`, sets language to C
8. GENie writes a `.sln` and `.vcxproj` file into `.zidar/projects/vs2022/`

---

## Sample 02: Hello Library

**Purpose**: Demonstrates how to create a reusable static library with the standard include/src directory split, and how `addLibProjects()` automatically handles unit tests.

**What it teaches**:
- The library directory convention (`include/` for public headers, `src/` for implementation)
- Using `addProject_lib()` to create a static library
- Using `addLibProjects()` instead of `projectAdd()` to enable sub-project discovery (tests, samples, tools)
- How unit tests are structured with precompiled headers
- How the Unity C test framework integrates with zidar

### Directory Structure

```
02_hello_library/
├── makefile
├── include/
│   └── hello_library.h           -- public header (visible to dependents)
├── src/
│   └── hello_library.c           -- implementation (private)
├── tests/
│   ├── 02_hello_library_pch.h    -- test PCH header
│   ├── 02_hello_library_pch.c    -- test PCH source
│   └── 02_hello_library_test.c   -- test runner
└── scripts/
    ├── genie.lua
    └── 02_hello_library.lua
```

### include/hello_library.h

```c
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

    /* Adds two integers */
    int helloLibraryAdd(int _a, int _b);

#ifdef __cplusplus
}
#endif
```

This is a **public header** — it lives in `include/` rather than `src/`. When another project depends on `02_hello_library`, zidar automatically adds this `include/` directory to the dependent's include paths. This means dependents can write `#include <hello_library.h>` without knowing the library's location on disk.

The `extern "C"` guard ensures the library can be used from both C and C++ code.

### src/hello_library.c

```c
#include <stdio.h>

int helloLibraryAdd(int _a, int _b)
{
    return _a + _b;
}
```

The implementation file lives in `src/`, which is **private** — it is not added to dependents' include paths. Only the library project itself can see files in `src/`.

### scripts/02_hello_library.lua

```lua
function projectAdd_02_hello_library()
    addProject_lib("02_hello_library")
end
```

`addProject_lib()` creates a `StaticLib` project. Unlike `addProject_cmd()`, it searches both `src/` and `include/` for source files and places the project in the `libs` IDE group.

### scripts/genie.lua

```lua
newoption { trigger = "zidar-path", description = "Path to zidar" }
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile("02_hello_library.lua")

solution "hello_library"
    setPlatforms()
    addLibProjects("02_hello_library")
```

The key difference from Sample 01 is the use of `addLibProjects()` instead of `projectAdd()`. This function is designed for library projects and automatically discovers sub-projects:

- **`--with-unittests`**: Scans the `tests/` directory and creates a `02_hello_library_test` project
- **`--with-samples`**: Scans `samples/` for subdirectories, each becoming a sample project
- **`--with-tools`**: Scans `tools/` for subdirectories, each becoming a tool project

Without these flags, only the library itself is added.

### tests/02_hello_library_pch.h

```c
#include <rg_core/rg_core.h>
#include <unity.h>
```

The test precompiled header includes the `rg_core` base library and the Unity C testing framework. Zidar detects PCH files by convention: it looks for `<projectname>_pch.h` and `<projectname>_pch.c` in the source directory.

### tests/02_hello_library_test.c

```c
#include <rg_core_test_pch.h>

RG_UNIT_TEST_SETUP      (RG_UNIT_TEST_NO_SETUP)
RG_UNIT_TEST_TEARDOWN   (RG_UNIT_TEST_NO_TEARDOWN)

extern void rgCoreTest_atomic(void);
extern void rgCoreTest_cpu(void);
extern void rgCoreTest_cmdline(void);
/* ... more test declarations ... */

int main(int _argc, char* _argv[])
{
    RG_UNUSED(_argc, _argv);

    RG_UNIT_TEST_PRINT_TITLE("rg_core")

    UNITY_BEGIN();
    RUN_TEST(rgCoreTest_atomic);
    RUN_TEST(rgCoreTest_cpu);
    RUN_TEST(rgCoreTest_cmdline);
    /* ... more test runs ... */
    return UNITY_END();
}
```

The test file uses the Unity C testing framework (zidar automatically links it for C test projects). It declares external test functions, then runs them through `UNITY_BEGIN()` / `RUN_TEST()` / `UNITY_END()`. This demonstrates how zidar structures test projects:

- Test sources live in the library's `tests/` directory
- The test project is named `<library>_test` (here: `02_hello_library_test`)
- C test projects link to the `unity` framework; C++ test projects link to `unittest-cpp`
- The test project automatically depends on the library being tested

### Build with Tests

```bash
genie --zidar-path=../../ --with-unittests vs2022
```

This generates a solution with two projects: `02_hello_library` (library) and `02_hello_library_test` (test executable).

---

## Sample 03: Tool Using a Library

**Purpose**: Demonstrates cross-project dependencies. A command-line tool depends on the library from Sample 02, and zidar automatically resolves the dependency — finding the library, adding its include paths, and linking it.

**What it teaches**:
- How to declare dependencies with `projectDependencies_<name>()`
- How zidar's dependency resolution finds projects across the directory tree
- How include paths from library dependencies are automatically configured
- How to consume a library's public API from a dependent project

### Directory Structure

```
03_tool_using_a_library/
├── makefile
├── scripts/
│   ├── genie.lua
│   └── 03_tool_using_a_library.lua
└── src/
    └── tool_using_a_library.c
```

Note the minimal structure — only the tool's own code. The library it depends on (`02_hello_library`) lives in a sibling directory. Zidar finds it automatically.

### scripts/03_tool_using_a_library.lua

```lua
function projectDependencies_03_tool_using_a_library()
    return { "02_hello_library" }
end

function projectAdd_03_tool_using_a_library()
    addProject_cmd("03_tool_using_a_library")
end
```

This is the first sample with a **dependency declaration**. The `projectDependencies_<name>()` callback returns a table of project names that this project depends on. When `projectAdd()` is called, zidar:

1. Calls `projectDependencies_03_tool_using_a_library()` → gets `{ "02_hello_library" }`
2. Searches for `02_hello_library`: checks the path cache, then searches up to 3 levels deep from the working directory, then walks up parent directories
3. Finds `../02_hello_library/` as a sibling directory
4. Loads `02_hello_library.lua` (the project script) if not already loaded
5. Recursively resolves `02_hello_library`'s own dependencies (it has none in this case)
6. Creates the `02_hello_library` project in the solution
7. Adds `02_hello_library/include/` to the tool's include paths
8. Links `02_hello_library` into the tool's executable

All of this happens automatically from a single line: `return { "02_hello_library" }`.

### src/tool_using_a_library.c

```c
#include <stdio.h>
#include <02_hello_library/include/hello_library.h>

int main(int argc, char* argv[])
{
    (void)argc;
    (void)argv;

    printf("2 + 3 = %d \n", helloLibraryAdd(2, 3));

    return 0;
}
```

The tool includes the library's public header and calls `helloLibraryAdd()`. The include path `<02_hello_library/include/hello_library.h>` works because zidar adds the library's parent directory to the include paths of dependent projects.

### scripts/genie.lua

```lua
newoption { trigger = "zidar-path", description = "Path to zidar" }
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile("03_tool_using_a_library.lua")

solution "tool_using_a_library"
    setPlatforms()
    projectAdd("03_tool_using_a_library")
    startproject "03_tool_using_a_library"
```

Only `projectAdd()` for the tool is called — zidar automatically pulls in `02_hello_library` as a dependency. The generated solution contains both projects with the correct build order. The `startproject` directive tells the IDE which project to run when pressing "Start Debugging".

### Dependency Resolution in Action

When you run `genie --zidar-path=../../ vs2022`:

1. The solution `tool_using_a_library` is created
2. `projectAdd("03_tool_using_a_library")` triggers dependency resolution
3. Zidar discovers `02_hello_library` needs to be built first
4. The generated Visual Studio solution has two projects:
   - `02_hello_library` (StaticLib) in the `libs` group
   - `03_tool_using_a_library` (ConsoleApp) in the `tools_cmd` group
5. Project dependencies are set so the library builds before the tool

---

## Sample 04: Qt App Using a Library

**Purpose**: Demonstrates Qt 6 integration. A Qt GUI application depends on the same library from Sample 02, showing how zidar handles MOC processing, precompiled headers with Qt includes, and Qt module linking alongside regular library dependencies.

**What it teaches**:
- Using `addProject_qt()` to create a Qt windowed application
- How Qt-specific prebuild steps (MOC, UIC, RCC) are generated automatically
- How to structure Qt precompiled headers
- How to combine Qt integration with regular library dependencies
- The `Q_OBJECT` macro and MOC processing flow

### Prerequisites

- Qt 6 installed with the `QTDIR` environment variable set (e.g. `C:\Qt\6.5.0\msvc2019_64`)
- Lua interpreter in PATH (for Qt prebuild steps)

### Directory Structure

```
04_Qt_app_using_a_library/
├── makefile
├── scripts/
│   ├── genie.lua
│   └── 04_Qt_app_using_a_library.lua
└── src/
    ├── 04_Qt_app_using_a_library.cpp      -- main() entry point
    ├── 04_Qt_app_using_a_library_pch.h    -- PCH with Qt includes
    ├── 04_Qt_app_using_a_library_pch.cpp  -- PCH source
    ├── main_window.h                      -- QMainWindow subclass (has Q_OBJECT)
    └── main_window.cpp                    -- MainWindow implementation
```

### scripts/04_Qt_app_using_a_library.lua

```lua
function projectDependencies_04_Qt_app_using_a_library()
    return { "02_hello_library" }
end

function projectAdd_04_Qt_app_using_a_library()
    addProject_qt("04_Qt_app_using_a_library")
end
```

This combines a dependency declaration (same as Sample 03) with `addProject_qt()` instead of `addProject_cmd()`. The Qt project type handles everything that a regular project does plus:

- Scanning `src/` for `.ui` files (Qt Designer forms) → generates UIC prebuild commands
- Scanning `src/` for `.qrc` files (Qt resources) → generates RCC prebuild commands
- Scanning `src/` for `.ts` files (translations) → generates lrelease prebuild commands
- Scanning headers for `Q_OBJECT` macros → generates MOC prebuild commands
- Linking default Qt modules: Core, Gui, Widgets, Network
- Setting the project kind to `WindowedApp` (no console window)

### src/04_Qt_app_using_a_library_pch.h

```cpp
#include <QtWidgets/QApplication>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMessageBox>
```

The precompiled header includes frequently-used Qt headers. This significantly speeds up compilation since Qt headers are large. Zidar detects this file by convention (matching `<projectname>_pch.h`).

### src/04_Qt_app_using_a_library_pch.cpp

```cpp
#include "04_Qt_app_using_a_library_pch.h"
```

The PCH source file simply includes the PCH header. This is the file that gets precompiled.

### src/main_window.h

```cpp
#ifndef RG_MAIN_WINDOW_H
#define RG_MAIN_WINDOW_H

#include <QtWidgets/QMainWindow>

QT_BEGIN_NAMESPACE
namespace Ui {
    class MainWindow;
}
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget* parent = nullptr);
    ~MainWindow();

private:
    Ui::MainWindow* ui;
};

#endif
```

This header contains the `Q_OBJECT` macro, which tells Qt's Meta-Object Compiler (MOC) that this class uses Qt's signal/slot mechanism. Zidar detects `Q_OBJECT` during project scanning and automatically generates a MOC prebuild command for this header. The generated `main_window_moc.cpp` file is compiled and linked into the project.

The `Ui::MainWindow` forward declaration is for Qt Designer form integration — the `_ui.h` file is generated from a `.ui` file by UIC (if one exists).

### src/main_window.cpp

```cpp
#include "main_window.h"
#include "../.qt/qt_ui/main_window_ui.h"

MainWindow::MainWindow(QWidget* parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
}

MainWindow::~MainWindow()
{
    delete ui;
}
```

The implementation includes the UIC-generated header from `.qt/qt_ui/main_window_ui.h`. This file is created by Qt's UIC tool from a `.ui` form file as a prebuild step. The generated `.qt/` directory is managed by zidar's Qt integration.

### src/04_Qt_app_using_a_library.cpp

```cpp
#include "04_Qt_app_using_a_library_pch.h"
#include "main_window.h"
#include <02_hello_library/include/hello_library.h>

int main(int argc, char* argv[])
{
    QApplication a(argc, argv);
    MainWindow w;
    w.show();
    QMessageBox::about(&w, QString("Call"),
        QString("2 + 3 = ") + QString::number(helloLibraryAdd(2, 3)));
    return a.exec();
}
```

The entry point creates a Qt application, shows the main window, and displays a message box that calls `helloLibraryAdd()` from the dependent `02_hello_library`. This demonstrates that Qt applications can use regular C/C++ library dependencies seamlessly — zidar handles both the Qt integration and the library linking.

### What Zidar Generates for Qt

When processing this project, `addProject_qt()` generates:

1. **MOC commands** for `main_window.h` (because it contains `Q_OBJECT`) → produces `main_window_moc.cpp`
2. **UIC commands** for any `.ui` files → produces `*_ui.h` files in `.qt/qt_ui/`
3. **RCC commands** for any `.qrc` files → produces `*_qrc.cpp`
4. **Linker settings** for Qt6Core, Qt6Gui, Qt6Widgets, Qt6Network (debug/release variants)
5. **DLL copy commands** (Windows) to copy Qt DLLs to the output directory

---

## Sample 05: Fancy Game Engine

**Purpose**: A complete multi-project solution demonstrating how a real-world codebase is organized with zidar. Shows multiple libraries, command-line tools, Qt tools, and game applications all coexisting in a single solution with proper categorization.

**What it teaches**:
- Organizing a large codebase with loader scripts (`libraries.lua`, `tools.lua`, `games.lua`)
- Using all four main project types together: `addProject_lib()`, `addProject_cmd()`, `addProject_qt()`, `addProject_game()`
- How each sub-project can also be built as a standalone project with its own `genie.lua`
- IDE group organization: libraries in `libs`, tools in `tools_cmd`/`tools`, games in `games`
- How `addProject_game()` switches between ConsoleApp (debug/release) and WindowedApp (retail)

### Directory Structure

```
05_fancy_game_engine/
├── scripts/
│   └── genie.lua                              -- top-level solution entry point
└── src/
    ├── libraries/
    │   ├── libraries.lua                      -- loader: loads all library scripts
    │   ├── lib1/
    │   │   ├── include/
    │   │   │   └── lib1.h                     -- public header
    │   │   ├── src/
    │   │   │   └── lib1.c                     -- implementation
    │   │   └── scripts/
    │   │       ├── genie.lua                  -- standalone build
    │   │       └── lib1.lua                   -- project definition
    │   └── lib2/
    │       ├── include/
    │       │   └── lib2.h
    │       ├── src/
    │       │   └── lib2.c
    │       └── scripts/
    │           ├── genie.lua
    │           └── lib2.lua
    ├── tools/
    │   ├── tools.lua                          -- loader: loads all tool scripts
    │   ├── toolCmdLine/
    │   │   ├── src/
    │   │   │   └── toolCmdLine.c              -- command-line tool
    │   │   └── scripts/
    │   │       ├── genie.lua
    │   │       └── toolCmdLine.lua
    │   └── toolQt/
    │       ├── src/
    │       │   └── toolQt.cpp                 -- Qt GUI tool
    │       └── scripts/
    │           ├── genie.lua
    │           └── toolQt.lua
    └── games/
        ├── games.lua                          -- loader: loads all game scripts
        ├── game1/
        │   ├── src/
        │   │   └── game1.c                   -- game executable
        │   └── scripts/
        │       ├── genie.lua
        │       └── game1.lua
        └── game2/
            ├── src/
            │   └── game2.c
            └── scripts/
                ├── genie.lua
                └── game2.lua
```

### Top-Level Entry Point

**scripts/genie.lua:**

```lua
newoption { trigger = "zidar-path", description = "Path to zidar" }
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile "../src/libraries/libraries.lua"
dofile "../src/tools/tools.lua"
dofile "../src/games/games.lua"

solution "fancy_game_engine"
    setPlatforms()
    projectAdd("lib1")
    projectAdd("lib2")
    projectAdd("toolCmdLine")
    projectAdd("toolQt")
    projectAdd("game1")
    projectAdd("game2")
```

Instead of loading individual project scripts, the top-level `genie.lua` loads **loader scripts** that aggregate projects by category. This keeps the entry point clean as the number of projects grows.

All six projects are added explicitly with `projectAdd()`. The generated IDE solution (e.g. Visual Studio) will organize them into groups:
- **libs**: `lib1`, `lib2`
- **tools_cmd**: `toolCmdLine`
- **tools**: `toolQt`
- **games**: `game1`, `game2`

### Loader Scripts

These one-line-per-project scripts aggregate all project definitions within a category:

**src/libraries/libraries.lua:**
```lua
dofile "lib1/scripts/lib1.lua"
dofile "lib2/scripts/lib2.lua"
```

**src/tools/tools.lua:**
```lua
dofile "toolCmdLine/scripts/toolCmdLine.lua"
dofile "toolQt/scripts/toolQt.lua"
```

**src/games/games.lua:**
```lua
dofile "game1/scripts/game1.lua"
dofile "game2/scripts/game2.lua"
```

As you add new libraries, tools, or games to the engine, you only need to add a `dofile` line to the corresponding loader script and a `projectAdd()` call to the main `genie.lua`.

### Library Projects

**src/libraries/lib1/scripts/lib1.lua:**
```lua
function projectAdd_lib1()
    addProject_lib("lib1")
end
```

**src/libraries/lib1/include/lib1.h:**
```c
#include <stdint.h>
```

**src/libraries/lib1/src/lib1.c:**
```c
#include <stdio.h>

int main(int argc, char* argv[])
{
    (void)argc;
    (void)argv;

    printf("Hello world!\n")

    return 0;
}
```

Both `lib1` and `lib2` follow the same structure — `include/` for public headers, `src/` for implementation, and `scripts/` for build definitions. They use `addProject_lib()` to create static libraries placed in the `libs` IDE group.

### Command-Line Tool

**src/tools/toolCmdLine/scripts/toolCmdLine.lua:**
```lua
function projectAdd_toolCmdLine()
    addProject_cmd("toolCmdLine")
end
```

**src/tools/toolCmdLine/src/toolCmdLine.c:**
```c
#include <stdio.h>

int main(int argc, char* argv[])
{
    (void)argc;
    (void)argv;

    printf("Hello world!\n")

    return 0;
}
```

A standard console application using `addProject_cmd()`, placed in the `tools_cmd` IDE group. In a real engine, this would be a tool like an asset converter or build pipeline utility.

### Qt Tool

**src/tools/toolQt/scripts/toolQt.lua:**
```lua
function projectAdd_toolQt()
    addProject_qt("toolQt")
end
```

**src/tools/toolQt/src/toolQt.cpp:**
```cpp
#include <stdio.h>

int main(int argc, char* argv[])
{
    (void)argc;
    (void)argv;

    printf("Hello world!\n")

    return 0;
}
```

A Qt windowed application using `addProject_qt()`, placed in the `tools` IDE group. In a real engine, this would be a level editor, asset browser, or debug inspector with a GUI.

### Game Projects

**src/games/game1/scripts/game1.lua:**
```lua
function projectAdd_game1()
    addProject_game("game1")
end
```

**src/games/game1/src/game1.c:**
```c
#include <stdio.h>

int main(int argc, char* argv[])
{
    (void)argc;
    (void)argv;

    printf("Hello world!\n")

    return 0;
}
```

Game projects use `addProject_game()`, which behaves differently from `addProject_cmd()`:

- In **debug** and **release** builds: creates a `ConsoleApp` (so you get a console window for debug output, log messages, and error reporting)
- In **retail** builds: creates a `WindowedApp` (no console window — clean presentation for end users)
- Games are placed in the `games` IDE group
- `addProject_game()` automatically adds `bgfx` as a dependency (the bgfx rendering library), since games typically need a graphics API

### Standalone Builds

Every sub-project has its own `genie.lua`, allowing independent development:

**src/libraries/lib1/scripts/genie.lua:**
```lua
newoption { trigger = "zidar-path", description = "Path to zidar" }
dofile(_OPTIONS["zidar-path"] .. "/zidar.lua")

dofile("lib1.lua")

solution "lib1"
    setPlatforms()
    projectAdd_lib1()
```

This means `lib1` can be built either:
- As part of the `fancy_game_engine` solution (via the top-level `genie.lua`)
- As a standalone project (by running GENie from `lib1/scripts/`)

This is useful during development when you want to work on a single component without generating the entire engine solution.

### Generated Solution Structure

When you run `genie --zidar-path=... vs2022` from `scripts/`, the generated Visual Studio solution contains:

```
fancy_game_engine.sln
├── libs/
│   ├── lib1          (StaticLib, C)
│   └── lib2          (StaticLib, C)
├── tools_cmd/
│   └── toolCmdLine   (ConsoleApp, C)
├── tools/
│   └── toolQt        (WindowedApp, C++)
└── games/
    ├── game1         (ConsoleApp/WindowedApp, C)
    └── game2         (ConsoleApp/WindowedApp, C)
```

---

## Patterns Summary

| Pattern | When to Use | Demonstrated In |
|---|---|---|
| `addProject_cmd()` | Console applications and command-line tools | Samples 01, 03, 05 |
| `addProject_lib()` | Reusable static/shared libraries | Samples 02, 05 |
| `addProject_game()` | Game executables (windowed in retail) | Sample 05 |
| `addProject_qt()` | Qt 6 GUI applications | Samples 04, 05 |
| `projectAdd()` | Adding a single project (with automatic dependency resolution) | All samples |
| `addLibProjects()` | Adding a library with its tests, samples, and tools | Sample 02 |
| `projectDependencies_*()` | Declaring dependencies on other projects | Samples 03, 04 |
| Loader scripts | Organizing many projects by category | Sample 05 |
| Standalone `genie.lua` per project | Enabling independent development of sub-projects | Sample 05 |
| PCH files (`*_pch.h` / `*_pch.c`) | Speeding up compilation with precompiled headers | Samples 02, 04 |
