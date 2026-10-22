#!/bin/sh
# 32-bit Windows build with the modern UCRT runtime.
# Host toolchain: gcc-mingw-w64-i686 (Arch: mingw-w64-gcc,
# Debian >= 12 / Ubuntu: gcc-mingw-w64-i686).
# Result: bin/aften-<ver>-win32.exe  (Windows 7+ with UCRT update)
set -e
cd "$(dirname "$0")/.."
ROOT=$(pwd)
VER=$(grep -o 'AFTEN_VERSION "[^"]*"' libaften/a52.h | cut -d'"' -f2)
mkdir -p bin
rm -rf build-ucrt && mkdir build-ucrt && cd build-ucrt
cmake .. -DCMAKE_TOOLCHAIN_FILE="$ROOT/mingw32.cmake" \
         -DCMAKE_BUILD_TYPE=Release \
         -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
         -DCMAKE_C_FLAGS="-std=gnu99 -fcommon" \
         -DSHARED=OFF > /dev/null
cmake --build . --target aften_exe -j"$(nproc)" > /dev/null
cp aften.exe "../bin/aften-$VER-win32.exe"
file "../bin/aften-$VER-win32.exe"
