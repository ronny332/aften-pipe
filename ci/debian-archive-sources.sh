#!/bin/sh
# Point apt at archive.debian.org.  EOL Debian suites (10 "buster",
# 11 "bullseye", ...) have their pools pruned on the main mirrors, so
# apt-get update partially 404s.  The archive is the authoritative,
# complete (frozen) source, including the security suite (buster:
# <suite>/updates, bullseye and newer: <suite>-security).
set -e
. /etc/os-release
DEB_MAJ=$(cut -d. -f1 /etc/debian_version)
if [ "$DEB_MAJ" -le 10 ]; then
    SEC="debian-security ${VERSION_CODENAME}/updates"
else
    SEC="debian-security ${VERSION_CODENAME}-security"
fi
cat > /etc/apt/sources.list <<EOF
deb [check-valid-until=no] http://archive.debian.org/debian ${VERSION_CODENAME} main
deb [check-valid-until=no] http://archive.debian.org/${SEC} main
EOF
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq -o Acquire::Check-Valid-Until=false
