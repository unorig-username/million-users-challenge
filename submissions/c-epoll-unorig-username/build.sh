#!/usr/bin/env bash
# Builds bin/server: libpq from the PostgreSQL 18.6 source tarball and the gzip compressor of libdeflate 1.26,
# both SHA-256 pinned and linked in statically.
set -euo pipefail
cd "$(dirname "$0")"
PG=postgresql-18.6 PGSHA=983ee554ec53dbeb9b70797bef9fcf4e67e117e7e48ca1463cc80b3ff8e8ff3f
LD=libdeflate-1.26 LDSHA=bba03fffc5538576213675ce6968fcff6ce2e67d82e4d5febea2d05f9f13cf85
mkdir -p bin deps
if [ ! -f deps/$PG/src/interfaces/libpq/libpq.a ]; then
  curl -fsSL -o deps/$PG.tar.gz https://ftp.postgresql.org/pub/source/v18.6/$PG.tar.gz
  echo "$PGSHA  deps/$PG.tar.gz" | sha256sum -c -
  rm -rf deps/$PG && tar -xzf deps/$PG.tar.gz -C deps
  # plain TCP + SCRAM only: no TLS, GSSAPI, readline, zlib or ICU
  (cd deps/$PG && CFLAGS="-O2 -march=x86-64-v2" ./configure -q --without-readline --without-zlib --without-icu \
     --without-openssl --without-gssapi --without-ldap >/dev/null \
   && make -s -C src/interfaces/libpq -j"$(nproc)" all-static-lib >/dev/null)
fi
if [ ! -f deps/$LD/libdeflate.h ]; then
  curl -fsSL -o deps/$LD.tar.gz https://github.com/ebiggers/libdeflate/archive/refs/tags/v1.26.tar.gz
  echo "$LDSHA  deps/$LD.tar.gz" | sha256sum -c -
  tar -xzf deps/$LD.tar.gz -C deps
fi
P=deps/$PG/src L=deps/$LD/lib
gcc -O2 -march=x86-64-v2 -flto=auto -fno-plt -pthread -Wall -Wno-unused-result -I$P/interfaces/libpq -I$P/include -Ideps/$LD \
  server.c $L/deflate_compress.c $L/gzip_compress.c $L/crc32.c $L/utils.c $L/x86/cpu_features.c \
  $P/interfaces/libpq/libpq.a $P/common/libpgcommon_shlib.a $P/port/libpgport_shlib.a -lm -o bin/server
