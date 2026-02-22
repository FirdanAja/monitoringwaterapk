@echo off
"D:\\KULIAH\\cmake\\3.22.1\\bin\\cmake.exe" ^
  "-HD:\\FLUTTER\\flutter_windows_3.41.2-stable\\flutter\\packages\\flutter_tools\\gradle\\src\\main\\scripts" ^
  "-DCMAKE_SYSTEM_NAME=Android" ^
  "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" ^
  "-DCMAKE_SYSTEM_VERSION=24" ^
  "-DANDROID_PLATFORM=android-24" ^
  "-DANDROID_ABI=armeabi-v7a" ^
  "-DCMAKE_ANDROID_ARCH_ABI=armeabi-v7a" ^
  "-DANDROID_NDK=D:\\KULIAH\\ndk\\28.2.13676358" ^
  "-DCMAKE_ANDROID_NDK=D:\\KULIAH\\ndk\\28.2.13676358" ^
  "-DCMAKE_TOOLCHAIN_FILE=D:\\KULIAH\\ndk\\28.2.13676358\\build\\cmake\\android.toolchain.cmake" ^
  "-DCMAKE_MAKE_PROGRAM=D:\\KULIAH\\cmake\\3.22.1\\bin\\ninja.exe" ^
  "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=D:\\SKRIPSIIIIIIIIIIIIIII\\APLIKASI MONITORING\\monitoringwaterapk\\android\\app\\build\\intermediates\\cxx\\debug\\1y3t1y6z\\obj\\armeabi-v7a" ^
  "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=D:\\SKRIPSIIIIIIIIIIIIIII\\APLIKASI MONITORING\\monitoringwaterapk\\android\\app\\build\\intermediates\\cxx\\debug\\1y3t1y6z\\obj\\armeabi-v7a" ^
  "-BD:\\SKRIPSIIIIIIIIIIIIIII\\APLIKASI MONITORING\\monitoringwaterapk\\android\\app\\.cxx\\debug\\1y3t1y6z\\armeabi-v7a" ^
  -GNinja ^
  -Wno-dev ^
  --no-warn-unused-cli ^
  "-DCMAKE_BUILD_TYPE=debug"
