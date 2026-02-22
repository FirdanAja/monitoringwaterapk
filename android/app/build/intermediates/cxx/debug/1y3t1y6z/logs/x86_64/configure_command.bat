@echo off
"D:\\KULIAH\\cmake\\3.22.1\\bin\\cmake.exe" ^
  "-HD:\\FLUTTER\\flutter_windows_3.41.2-stable\\flutter\\packages\\flutter_tools\\gradle\\src\\main\\scripts" ^
  "-DCMAKE_SYSTEM_NAME=Android" ^
  "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" ^
  "-DCMAKE_SYSTEM_VERSION=24" ^
  "-DANDROID_PLATFORM=android-24" ^
  "-DANDROID_ABI=x86_64" ^
  "-DCMAKE_ANDROID_ARCH_ABI=x86_64" ^
  "-DANDROID_NDK=D:\\KULIAH\\ndk\\28.2.13676358" ^
  "-DCMAKE_ANDROID_NDK=D:\\KULIAH\\ndk\\28.2.13676358" ^
  "-DCMAKE_TOOLCHAIN_FILE=D:\\KULIAH\\ndk\\28.2.13676358\\build\\cmake\\android.toolchain.cmake" ^
  "-DCMAKE_MAKE_PROGRAM=D:\\KULIAH\\cmake\\3.22.1\\bin\\ninja.exe" ^
  "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=D:\\SKRIPSIIIIIIIIIIIIIII\\APLIKASI MONITORING\\monitoringwaterapk\\android\\app\\build\\intermediates\\cxx\\debug\\1y3t1y6z\\obj\\x86_64" ^
  "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=D:\\SKRIPSIIIIIIIIIIIIIII\\APLIKASI MONITORING\\monitoringwaterapk\\android\\app\\build\\intermediates\\cxx\\debug\\1y3t1y6z\\obj\\x86_64" ^
  "-BD:\\SKRIPSIIIIIIIIIIIIIII\\APLIKASI MONITORING\\monitoringwaterapk\\android\\app\\.cxx\\debug\\1y3t1y6z\\x86_64" ^
  -GNinja ^
  -Wno-dev ^
  --no-warn-unused-cli ^
  "-DCMAKE_BUILD_TYPE=debug"
