# Zidar - Project Types

Zidar supports several project types, each with its own handler function, default flags, and conventions.

## Callback System

Every project in zidar is defined through callback functions registered in the global table. The naming convention is `functionName_projectName()` where the project name has dashes and dots replaced with underscores.

### Required Callbacks

**`projectAdd_[name]()`** - Called when a project needs to be added to the solution. Must call one of the `addProject_*` functions.

```lua
function projectAdd_my_lib()
    addProject_lib("my_lib")
end
```

### Optional Callbacks

**`projectDependencies_[name]()`** - Returns a table of dependency names.

```lua
function projectDependencies_my_app()
    return { "rg_core", "rg_prof" }
end
```

**`projectSource_[name]()`** - Returns a git URL for automatic downloading of 3rd party libraries.

```lua
function projectSource_my_3rd_lib()
    return "https://github.com/user/repo.git"
end
```

**`projectDescription_[name]()`** - Returns a human-readable description string.

```lua
function projectDescription_my_lib()
    return "My utility library"
end
```

**`projectExtraConfig_[name]()`** - Called per build configuration to apply extra settings.

```lua
function projectExtraConfig_my_lib()
    defines { "MY_EXTRA_DEFINE" }
    buildoptions { "/W4" }
end
```

**`projectExtraConfigExecutable_[name]()`** - Called for executable projects and their dependencies.

```lua
function projectExtraConfigExecutable_my_lib()
    links { "opengl32" }
end
```

**`projectDependencyConfig_[name]()`** - Called when this project is used as a dependency.

```lua
function projectDependencyConfig_my_lib()
    defines { "USING_MY_LIB=1" }
end
```

**`projectHeaderOnlyLib_[name]`** - Define as any truthy value to mark a library as header-only (skip linking).

```lua
projectHeaderOnlyLib_my_header_lib = true
```

## Project Type: Library

**Function:** `addProject_lib(_name, _libType, _shared, _disablePCH)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `_name` | string | required | Project name |
| `_libType` | LibraryType | nil | Library category for IDE grouping |
| `_shared` | boolean | false | Build as shared library (DLL) |
| `_disablePCH` | boolean | false | Disable precompiled headers |

**Flags:** `StaticRuntime`, `NoEditAndContinue`, `NoRTTI`, `ExtraWarnings`, `NoExceptions`

**Language:** Auto-detected (C or C++) based on source file extensions.

**Directory structure:**
```
my_lib/
  include/      -- public headers (added to include path for dependents)
  src/          -- source files and private headers
  3rd/          -- optional project-specific 3rd party code
```

**Library types** control IDE solution grouping:

| Type | IDE Group |
|---|---|
| `LibraryType.Runtime` (default) | `libs` |
| `LibraryType.Tool` | `libs_tools` |
| `LibraryType.Game` | `libs_game` |

**Example:**

```lua
function projectAdd_rg_core()
    addProject_lib("rg_core")
end
```

**With sub-projects** (samples, tests, tools):

```lua
-- In genie.lua:
solution "rg_core"
    setPlatforms()
    addLibProjects("rg_core")  -- handles samples/tests/tools automatically
```

Use `addLibProjects()` instead of `projectAdd()` to automatically include:
- Unit tests (with `--with-unittests`)
- Samples (with `--with-samples`, only when library is the main solution)
- Tools (with `--with-tools`)

## Project Type: Command-Line Tool

**Function:** `addProject_cmd(_name)`

| Parameter | Type | Description |
|---|---|---|
| `_name` | string | Project name |

**Flags:** `StaticRuntime`, `NoEditAndContinue`, `NoRTTI`, `ExtraWarnings`, `NoExceptions`

**Kind:** `ConsoleApp`

**Directory structure:**
```
my_tool/
  src/          -- source files (also used as include path)
```

**Example:**

```lua
function projectAdd_my_tool()
    addProject_cmd("my_tool")
end
```

## Project Type: Game

**Function:** `addProject_game(_name)`

| Parameter | Type | Description |
|---|---|---|
| `_name` | string | Project name |

**Flags:** `StaticRuntime`, `NoEditAndContinue`, `NoRTTI`, `ExtraWarnings`, `NoExceptions`

**Kind:** `WindowedApp` in retail, `ConsoleApp` in debug/release.

**Dependencies:** Automatically includes `rg_app` and `bgfx`.

**Directory structure:**
```
my_game/
  src/          -- source files
```

**Example:**

```lua
function projectAdd_my_game()
    addProject_game("my_game")
end
```

## Project Type: Qt Application

**Function:** `addProject_qt(_name, _libraryType, _includes, _prebuildcmds, _extraQtModules)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `_name` | string | required | Project name |
| `_libraryType` | LibraryType | nil | If `LibraryType.Tool`, builds as StaticLib |
| `_includes` | table | {} | Additional include directories |
| `_prebuildcmds` | table | {} | Additional prebuild commands |
| `_extraQtModules` | table | {} | Extra Qt modules beyond the defaults |

**Default Qt modules:** `Core`, `Gui`, `Widgets`, `Network`

**Flags:** `StaticRuntime`, `NoEditAndContinue`, `NoRTTI`, `ExtraWarnings`

**Kind:** `WindowedApp` (or `StaticLib` when `_libraryType == LibraryType.Tool`)

**Language:** Always C++.

**Requires:** `QTDIR` environment variable pointing to Qt root.

Qt files are automatically discovered from the project directory:
- `inc/**/*.h` and `src/**/*.h` - scanned for `Q_OBJECT` macro (MOC)
- `src/**/*.ui` - Qt Designer forms (UIC)
- `src/**/*.qrc` - Qt resource files (RCC)
- `src/**/*.ts` - Qt translation files (lrelease)

Generated files are placed in `.qt/` subdirectories:
```
.qt/
  qt_moc/       -- *_moc.cpp files
  qt_ui/        -- *_ui.h files
  qt_qrc/       -- *_qrc.cpp files
  qt_qm/        -- *_ts.qm files
```

**Example:**

```lua
function projectAdd_my_qt_app()
    addProject_qt("my_qt_app", nil, nil, nil, { "OpenGL", "Svg" })
end
```

**IDE virtual paths** organize Qt files:

| Virtual Path | Files |
|---|---|
| `qt/generated/ui` | `*_ui.h` |
| `qt/generated/moc` | `*_moc.cpp` |
| `qt/generated/qrc` | `*_qrc.cpp` |
| `qt/translation` | `*.ts` |
| `qt/forms` | `*.ui` |
| `qt/resources` | `*.qrc` |

## Project Type: 3rd Party Library

**Function:** `addProject_3rdParty_lib(_name, _libFiles, _exceptions)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `_name` | string | required | Project name |
| `_libFiles` | table | required | Source file patterns |
| `_exceptions` | boolean | false | Allow C++ exceptions |

**Flags:** `StaticRuntime`, `NoEditAndContinue`, `NoPCH`, `MinimumWarnings`

**Kind:** `StaticLib`

Used for wrapping external code that doesn't follow zidar conventions:

```lua
function projectAdd_stb()
    addProject_3rdParty_lib("stb", { "3rd/stb/*.c", "3rd/stb/*.h" })
end
```

## Project Type: Library Sample

**Function:** `addProject_lib_sample(_name, _sampleName)`

Automatically created by `addLibSubProjects_samples()` when `--with-samples` is set. Each subdirectory under `samples/` becomes a separate `ConsoleApp` project.

```
my_lib/
  samples/
    sample_basic/
      src/main.cpp
    sample_advanced/
      src/main.cpp
```

## Project Type: Library Unit Test

**Function:** `addProject_lib_test(_name)`

Automatically created by `addLibSubProjects_unittests()` when `--with-unittests` is set. The test project is named `[name]_test`.

- C++ tests depend on `unittest-cpp`
- C tests depend on `unity` (the C testing framework)

```
my_lib/
  tests/
    src/test_main.cpp
```

## Project Type: Library Tool

**Function:** `addProject_lib_tool(_name, _libName)`

Automatically created by `addLibSubProjects_tools()` when `--with-tools` is set. Each subdirectory under `tools/` becomes a separate `ConsoleApp` project.

## Dependency Resolution

When `projectAdd()` or `addDependencies()` is called, zidar:

1. Calls `projectDependencies_[name]()` to get declared dependencies
2. Merges with any additional dependencies passed as parameters
3. Loads each dependency's script if not already loaded
4. Recursively resolves nested dependencies
5. For `gmake` actions, sorts dependencies by sub-dependency count (most dependencies first) for correct linking order
6. Calls `configDependency()` for each dependency
7. Caches the resolved list for reuse

Dependencies can be specified as strings or tables. A table dependency like `{"rg_app", "bgfx"}` is treated as a compound name.

## Utility Functions

| Function | Description |
|---|---|
| `mergeTables(...)` | Merges tables removing duplicates |
| `isTable(_var)` | Returns true if variable is a table |
| `projectNameCleanup(_name)` | Replaces dashes and dots with underscores |
| `projectGetBaseName(_name)` | Extracts base name from table or string |
| `projectGetPath(_name, _canFail)` | Finds project directory |
| `projectGetScriptPath(_name)` | Finds project build script |
| `projectIsCPP(_files)` | Returns true if files contain C++ sources |
| `projectSourceFilesWildcard(...)` | Generates source file glob patterns |
| `fileRead(_file)` | Reads entire file as string |
| `getToolForHost(_name)` | Returns platform-specific tool path |
| `isRunningOnWindows()` | Returns true on Windows |
| `actionUsesMSVC()` | Returns true for Visual Studio actions |
| `actionUsesXcode()` | Returns true for Xcode actions |
