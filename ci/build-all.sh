#!/bin/sh
# Build all release assets.
#  - win32 UCRT build: from the host, if a mingw-w64 toolchain is present
#  - win32 msvcrt (XP) build: debian:11 container
#  - linux static build: debian:10 container
# Container engine: podman (rootless) or docker.
set -e
cd "$(dirname "$0")/.."
ROOT=$(pwd)

ci/build-win32-ucrt.sh || echo "skip UCRT build (no host mingw-w64?)"

RUN=$(command -v podman || command -v docker || true)
if [ -z "$RUN" ]; then
    echo "no podman/docker found; skipping msvcrt + linux container builds"
    exit 0
fi

"$RUN" run --rm -v "$ROOT":/src:z -w /src debian:11-slim sh -c /src/ci/build-win32-msvcrt.sh
"$RUN" run --rm -v "$ROOT":/src:z -w /src debian:10-slim sh -c /src/ci/build-linux-static.sh

ls -la bin/
