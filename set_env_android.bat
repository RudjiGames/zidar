@echo off
IF %1.==. GOTO NoNDKpath

echo Setting Android environment variables
echo NDK root set at %1

setx ANDROID_NDK_ROOT	%1
setx ANDROID_NDK_ARM	%1/toolchains/arm-linux-androideabi-4.9/prebuilt/windows-x86_64
setx ANDROID_NDK_MIPS	%1/toolchains/mipsel-linux-android-4.9/prebuilt/windows-x86_64
setx ANDROID_NDK_X86	%1/toolchains/x86-4.9/prebuilt/windows-x86_64

goto done

:NoNDKpath
echo Error - missing argument!
echo Usage: set_env_android.bat [path to NDK]
echo Example:
echo    set_env_android d:/android-ndk-r12b
echo NB: use forward slash!

:done

