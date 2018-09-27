#!/usr/bin/env bash

set -ex

# Install all packages required to compile the LibGraphQLParser project
apk --no-cache add \
  linux-headers \
  build-base \
  libc-dev \
  python2 \
  cmake \
  bison \
  flex

# Clone the project, configure, compile and install it
git clone https://github.com/graphql/libgraphqlparser.git /tmp/libgraphqlparser
wget --quiet -O /tmp/release-1.8.0.tar.gz https://github.com/google/googletest/archive/release-1.8.0.tar.gz && \
  tar -xf /tmp/release-1.8.0.tar.gz googletest-release-1.8.0 -C /tmp/libgraphqlparser/test

cd /tmp/libgraphqlparser && \
  cmake . -Dtest=ON && \
  make && \
  make install
