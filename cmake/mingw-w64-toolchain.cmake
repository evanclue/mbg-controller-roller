# Cross-compilation settings for the Windows build, driven by the environment
# that setup-windows-toolchain.sh exports.
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(MINGW_ROOT "$ENV{MBG_WIN_MINGW_ROOT}")
set(WIN_SYSROOT "$ENV{MBG_WIN_SYSROOT}")

set(CMAKE_C_COMPILER   ${MINGW_ROOT}/bin/x86_64-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER ${MINGW_ROOT}/bin/x86_64-w64-mingw32-g++)
set(CMAKE_RC_COMPILER  ${MINGW_ROOT}/bin/x86_64-w64-mingw32-windres)
set(CMAKE_AR           ${MINGW_ROOT}/bin/x86_64-w64-mingw32-gcc-ar CACHE FILEPATH "")
set(CMAKE_RANLIB       ${MINGW_ROOT}/bin/x86_64-w64-mingw32-gcc-ranlib CACHE FILEPATH "")

# Releases have to keep running on pre-AVX processors.
set(CMAKE_C_FLAGS_INIT   "-march=x86-64 -mtune=generic")
set(CMAKE_CXX_FLAGS_INIT "-march=x86-64 -mtune=generic")

set(CMAKE_FIND_ROOT_PATH ${MINGW_ROOT}/x86_64-w64-mingw32 ${WIN_SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
