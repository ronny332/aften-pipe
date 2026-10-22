# MinGW-w64 cross-compile toolchain file (Linux host -> 32-bit Windows)
# usage:
#   cmake -B build -DCMAKE_TOOLCHAIN_FILE=mingw32.cmake \
#         -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
#         -DCMAKE_C_FLAGS="-std=gnu99 -fcommon"
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86)
set(CMAKE_C_COMPILER i686-w64-mingw32-gcc)
set(CMAKE_RC_COMPILER i686-w64-mingw32-windres)
set(CMAKE_FIND_ROOT_PATH /usr/i686-w64-mingw32)
set(CMAKE_EXE_LINKER_FLAGS "-static -s" CACHE STRING "")
