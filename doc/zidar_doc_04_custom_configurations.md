# Zidar - Custom Configurations and Advanced Features

## Toolchain Configuration

The toolchain is configured automatically based on command line options. The `setPlatforms()` function must be called inside a `solution` block to initialize it.

```lua
solution "my_solution"
    setPlatforms()
```

This sets up:
- Platform targets (x32, x64, native)
- Build configurations (debug, release, retail)
- Compiler-specific flags and paths
- Platform-specific defines and libraries

### Compiler Detection

Zidar detects the compiler from GENie's `_ACTION` variable and the `--gcc`, `--vs`, or `--xcode` options:

| Action | Compiler |
|---|---|
| `vs2017` - `vs2022` | MSVC |
| `xcode*` | Apple Clang (Xcode) |
| `gmake` with `--gcc=linux-gcc` | GCC |
| `gmake` with `--gcc=linux-clang` | Clang |
| `gmake` with `--gcc=android-*` | Android NDK |
| `gmake` with `--gcc=wasm` | Emscripten |

### Target OS Detection

The target OS is automatically determined from compiler options:

```lua
local os = getTargetOS()       -- returns "windows", "linux", "osx", "ios", "android", etc.
local compiler = getTargetCompiler()  -- returns compiler identifier string
```

### Platform-Specific Helpers

```lua
isRunningOnWindows()    -- host OS check (cached at load time)
isAppleTarget()         -- true for ios, tvos, xros, osx targets
actionUsesMSVC()        -- true for vs* actions
actionUsesXcode()       -- true for xcode* actions
```

## Custom Project Configuration

### Per-Project Extra Config

Define `projectExtraConfig_[name]()` to apply settings per build configuration:

```lua
function projectExtraConfig_my_lib()
    configuration { "windows" }
        defines { "WIN32_LEAN_AND_MEAN" }
        links { "ws2_32", "winmm" }

    configuration { "linux" }
        links { "pthread", "dl" }

    configuration {}
end
```

This callback is invoked once per platform/configuration combination during `configurations.lua` processing.

### Per-Executable Extra Config

Define `projectExtraConfigExecutable_[name]()` for settings that apply when a project is built as an executable (or when it's a dependency of an executable):

```lua
function projectExtraConfigExecutable_my_lib()
    configuration { "windows" }
        links { "opengl32" }
    configuration {}
end
```

### Per-Dependency Config

Define `projectDependencyConfig_[name]()` for settings applied to any project that depends on this one:

```lua
function projectDependencyConfig_my_lib()
    defines { "USING_MY_LIB=1" }
    includedirs { "/some/special/path" }
end
```

## Compiler Flags

### Flag Sets by Project Type

| Flag Set | Used By | Flags |
|---|---|---|
| `Flags_ThirdParty` | 3rd party libs | `StaticRuntime`, `NoEditAndContinue`, `NoPCH`, `MinimumWarnings` |
| `Flags_Libraries` | Libraries, tools | `StaticRuntime`, `NoEditAndContinue`, `NoRTTI`, `ExtraWarnings`, `NoExceptions` |
| `Flags_Tests` | Unit tests | `StaticRuntime`, `NoEditAndContinue`, `NoRTTI`, `ExtraWarnings` |
| `Flags_Cmd` | Console apps, games | `StaticRuntime`, `NoEditAndContinue`, `NoRTTI`, `ExtraWarnings`, `NoExceptions` |
| `Flags_QtTool` | Qt applications | `StaticRuntime`, `NoEditAndContinue`, `NoRTTI`, `ExtraWarnings` |

### Configuration-Specific Flags

| Configuration | Extra Flags | Extra Defines |
|---|---|---|
| `debug` | `Symbols` | `RG_DEBUG_BUILD`, `_DEBUG`, `DEBUG` |
| `release` | `NoFramePointer`, `OptimizeSpeed`, `NoBufferSecurityCheck`, `Symbols` | `RG_RELEASE_BUILD`, `NDEBUG` |
| `retail` | `NoFramePointer`, `OptimizeSpeed`, `NoBufferSecurityCheck` | `RG_RETAIL_BUILD`, `NDEBUG`, `RETAIL` |

These tables are global and can be modified before `setPlatforms()` is called:

```lua
-- Add a custom define to all debug builds
table.insert(ExtraDefines["debug"], "MY_CUSTOM_DEBUG=1")
```

## Qt Integration

### Setup

Set the `QTDIR` environment variable to point to your Qt installation root (e.g. `C:\Qt\6.5.0\msvc2019_64`).

### How It Works

1. `addProject_qt()` discovers `.h`, `.ui`, `.qrc`, and `.ts` files in the project
2. `configurations.lua` calls `qtConfigure()` for each build configuration
3. `qtConfigure()` registers prebuild commands that invoke `qtprebuild.lua`
4. At build time, `qtprebuild.lua` runs the appropriate Qt tool (moc, uic, rcc, lrelease)
5. Only headers containing `Q_OBJECT` are processed by MOC

### Platform-Specific Qt Behavior

**Windows:**
- Qt DLLs are automatically copied to the output directory
- Platform plugins (`qwindows.dll`, `qminimal.dll`) are copied
- MSVC: Forces PCH inclusion via `/FI`, adds `/Zc:__cplusplus /std:c++20 /permissive-`
- MinGW: Copies `libstdc++` DLL

**Linux:**
- Uses `pkg-config` for library flags and include paths
- Set `PKG_CONFIG_PATH` to point to your Qt's `lib/pkgconfig` directory

**macOS:**
- Uses framework linking (`-framework QtCore`, etc.)
- Creates symbolic links for framework headers

### Extra Qt Modules

Pass additional modules beyond the default `{Core, Gui, Widgets, Network}`:

```lua
function projectAdd_my_qt_app()
    addProject_qt("my_qt_app", nil, nil, nil, { "OpenGL", "Svg", "PrintSupport" })
end
```

## Embedded Shader Support

### Setup

Projects that use bgfx embedded shaders need to define the `_shaderFiles` global before calling `projectConfig()`.

### Shader Naming Convention

Shader source files (`.sc`) must be prefixed:
- `vs_*.sc` - Vertex shaders
- `fs_*.sc` - Fragment shaders
- `cs_*.sc` - Compute shaders
- `varying.def` - Varying definition file (skipped)

### Compilation Targets

Each shader is compiled to multiple backends:

| Backend | Vertex Profile | Fragment Profile | Compute Profile |
|---|---|---|---|
| GLSL (Linux) | default | default | 430 |
| SPIR-V (Vulkan) | spirv | spirv | spirv |
| DirectX 9 | vs_3_0 | ps_3_0 | n/a |
| DirectX 11 | vs_4_0 | ps_4_0 | cs_5_0 |
| Metal (iOS) | metal | metal | n/a |

Output is a `.bin.h` header with C arrays named `[filename]_glsl`, `[filename]_spv`, `[filename]_dx9`, `[filename]_dx11`, `[filename]_mtl`.

## 3rd Party Dependency Management

### Automatic Downloads

When a dependency isn't found locally, zidar checks `RG_3RD_PARTY_SCRIPTS` for a matching script in `zidar/3rd/`. If the script defines a `projectSource_[name]()` function, zidar downloads it via `git clone`.

### Custom Dependency Directory

Set `RG_ZIDAR_DEPENDENCY_DIR` environment variable to override the default `.3rd` directory.

### 3rd Party Script Structure

Place scripts in `zidar/3rd/[name].lua`:

```lua
function projectSource_my_3rd_lib()
    return "https://github.com/user/repo.git"
end

function projectAdd_my_3rd_lib()
    addProject_3rdParty_lib("my_3rd_lib", {
        projectInstallDestination("my_3rd_lib") .. "/src/*.c",
        projectInstallDestination("my_3rd_lib") .. "/src/*.h",
    })
end
```

## Atexit Mechanism

Zidar provides an `atexit()` function for registering cleanup callbacks:

```lua
atexit(function()
    print("Build complete!")
end)
```

Callbacks execute in reverse registration order (LIFO) and are triggered:
- When `os.exit()` is called
- After GENie's `premake.action.call()` completes (normal termination)

Zidar uses this internally to restore the Windows console code page after UTF-8 output.

## Console Output

### Text Coloring

```lua
-- Available colors
Color.Black, Color.Red, Color.Green, Color.Yellow,
Color.Blue, Color.Magenta, Color.Cyan, Color.White, Color.Default

-- Colored text
textColor("message", Color.Green)                    -- green text
textColor("message", Color.Red, Color.Yellow)        -- red on yellow
textColor("message", Color.Yellow, nil, true)        -- blinking yellow

-- Output helpers
printInfo("status message")                          -- cyan
printInfo("custom color", Color.Green)               -- green
printWarning("something wrong")                      -- blinking yellow
printErrorAndExit("fatal error")                     -- red on yellow, exits
```

### UTF-8 Support

On Windows, zidar automatically switches the console to UTF-8 (code page 65001) at startup and restores the original code page at exit. This enables Unicode characters in build output.

## Virtual Paths (IDE Organization)

Files are organized into IDE virtual folders:

| Virtual Path | Patterns |
|---|---|
| `shaders` | `*.sc` |
| `include` | `*.h`, `*.hpp`, `*.hxx`, `*.inl` |
| `src` | `*.c`, `*.cc`, `*.cxx`, `*.cpp`, `src/*.h`, `src/*.hpp`, `src/*.hxx`, `src/*.inl` |
| `qt/generated/ui` | `*_ui.h` |
| `qt/generated/moc` | `*_moc.cpp` |
| `qt/generated/qrc` | `*_qrc.cpp` |
| `qt/translation` | `*.ts` |
| `qt/forms` | `*.ui` |
| `qt/resources` | `*.qrc` |
