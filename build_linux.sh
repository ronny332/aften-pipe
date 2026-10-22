#!/bin/sh
# Starter build for POSIX systems: aften, wavinfo, wavrms and wavfilter.
#
#   ./build_linux.sh                Release build in ./build
#   ./build_linux.sh clean          wipe ./build first
#   ./build_linux.sh debug          Debug build (slow, assertions on)
#   ./build_linux.sh -j 4           limit parallelism
#   ./build_linux.sh --target aften_exe
#   ./build_linux.sh -DDOUBLE=ON    arbitrary -D for cmake
#
# No arguments are needed; -DCMAKE_POLICY_VERSION_MINIMUM=3.5 is in here
# because this tree predates CMake 3.  Building the release *assets*
# (fully static, in containers) is ci/build-all.sh, not this script.

set -e
cd "$(dirname "$0")"

BUILD=build
TYPE=Release
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
TARGET=
EXTRA=

usage() {
    sed -n '3,14p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
    case "$1" in
        clean)       rm -rf "$BUILD" ;;
        debug)       TYPE=Debug ;;
        -j)          shift; JOBS=${1:?-j needs a number} ;;
        --target)    shift; TARGET=${1:?--target needs a target} ;;
        -h|--help)   usage; exit 0 ;;
        -D*|-G*)     EXTRA="$EXTRA $1" ;;
        -*)          echo "unknown option: $1  (try --help; -D<var>=<value> is passed to cmake)" >&2
                     exit 2 ;;
        *)           echo "unknown option: $1 (try --help)" >&2; exit 2 ;;
    esac
    shift
done

if ! command -v cmake >/dev/null 2>&1; then
    echo "cmake not found.  Arch: sudo pacman -S cmake gcc" >&2
    echo "                    Debian/Ubuntu: sudo apt install cmake build-essential" >&2
    exit 1
fi

# shellcheck disable=SC2086
cmake -S . -B "$BUILD" -DCMAKE_BUILD_TYPE="$TYPE" \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 $EXTRA
# shellcheck disable=SC2086
cmake --build "$BUILD" -j"$JOBS" ${TARGET:+--target "$TARGET"}

echo
echo "built: $BUILD/aften  ($TYPE, -j$JOBS)"
ls -1 "$BUILD"/wavfilter "$BUILD"/wavinfo "$BUILD"/wavrms 2>/dev/null || true
"$BUILD/aften" -version 2>&1 | head -2
