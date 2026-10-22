#!/bin/sh
# 32-bit Windows build with the classic msvcrt.dll runtime:
# true old-school binary, runs on Windows XP and newer, no updates,
# no redistributables.
# Run INSIDE a debian:11 (bullseye) container; its mingw-w64 still
# defaults to the msvcrt runtime (Debian 12 switched to UCRT).
# Result: bin/aften-<ver>-win32-xp.exe
set -e
cd "$(dirname "$0")/.."
ROOT=$(pwd)
VER=$(grep -o 'AFTEN_VERSION "[^"]*"' libaften/a52.h | cut -d'"' -f2)
mkdir -p bin

apt-get install -y -qq --no-install-recommends cmake make \
    gcc-mingw-w64-i686 binutils-mingw-w64-i686 > /dev/null 2>&1 || {
    . ci/debian-archive-sources.sh
    apt-get install -y -qq --no-install-recommends cmake make \
        gcc-mingw-w64-i686 binutils-mingw-w64-i686 > /dev/null
}

i686-w64-mingw32-gcc --version | head -1
rm -rf build-msvcrt && mkdir build-msvcrt && cd build-msvcrt
cmake .. -DCMAKE_TOOLCHAIN_FILE="$ROOT/mingw32.cmake" \
         -DCMAKE_BUILD_TYPE=Release \
         -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
         -DCMAKE_C_FLAGS="-std=gnu99 -fcommon" \
         -DSHARED=OFF > /dev/null
cmake --build . --target aften_exe -j"$(nproc)" > /dev/null
cp aften.exe "../bin/aften-$VER-win32-xp.exe"
# runtime sanity: must import msvcrt.dll and NO api-ms-win-crt-*
i686-w64-mingw32-objdump -p "../bin/aften-$VER-win32-xp.exe" | grep 'DLL Name'
