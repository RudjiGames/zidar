call clean.bat
call android update project -p . --target android-@@ANDROID_VER@@
call %ANDROID_NDK_ROOT%/ndk-build.cmd NDK_DEBUG=1
call ant debug
call adb install -r bin/@@SHORT_NAME@@-debug.apk

