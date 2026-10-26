#!/usr/bin/env bash
# Runs once as root on a clean Ubuntu 24.04: a C compiler and the tools build.sh uses to fetch and configure the libpq source (configure insists on bison and flex).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends build-essential curl ca-certificates bison flex
gcc --version | head -1
