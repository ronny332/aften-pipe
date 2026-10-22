#!/bin/sh
# Point apt at archive.debian.org.  EOL Debian suites (10 "buster",
# 11 "bullseye", ...) have their pools pruned on the main mirrors, so
# apt-get update partially 404s.  The archive is the authoritative,
# complete (frozen) source.  Used by the container build scripts.
set -e
. /etc/os-release
cat > /etc/apt/sources.list <<EOF
deb [check-valid-until=no] http://archive.debian.org/debian ${VERSION_CODENAME} main
EOF
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq -o Acquire::Check-Valid-Until=false
