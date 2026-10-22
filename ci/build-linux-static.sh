#!/bin/sh
# Fully static x86_64 Linux build.
# Run INSIDE a debian:10 (buster) container: gcc 8 + glibc 2.28 era
# toolchain, so the binary meets no glibc it cannot greet.  -static
# makes it independent of the system libc entirely.
# Result: bin/aften-<ver>-linux-x86_64
set -e
cd "$(dirname "$0")/.."
VER=$(grep -o 'AFTEN_VERSION "[^"]*"' libaften/a52.h | cut -d'"' -f2)
mkdir -p bin

apt-get install -y -qq --no-install-recommends cmake make gcc libc6-dev \
    file > /dev/null 2>&1 || {
    . ci/debian-archive-sources.sh
    apt-get install -y -qq --no-install-recommends cmake make gcc libc6-dev \
        file > /dev/null
}

gcc --version | head -1
rm -rf build-linux && mkdir build-linux && cd build-linux
cmake .. -DCMAKE_BUILD_TYPE=Release \
         -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
         -DCMAKE_EXE_LINKER_FLAGS="-static -s" \
         -DSHARED=OFF > /dev/null
cmake --build . --target aften_exe -j"$(nproc)" > /dev/null
cp aften "../bin/aften-$VER-linux-x86_64"
file "../bin/aften-$VER-linux-x86_64"
