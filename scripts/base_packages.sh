#!/usr/bin/env bash

set -ex

# Disable documentation, install messages and suggestions when installing gems
mkdir -p /usr/local/etc && \
  { \
		echo 'install: --no-document --no-post-install-message --no-suggestions'; \
		echo 'update: --no-document --no-post-install-message --no-suggestions'; \
    echo 'gem: --no-document --no-post-install-message --no-suggestions'; \
	} >> /usr/local/etc/gemrc && \
  chmod uog+r /usr/local/etc/gemrc

# Install base packages
apk --no-cache add \
  postgresql-client \
  ruby-bigdecimal \
  ruby-io-console \
  ca-certificates \
  ruby-bundler \
  libstdc++ \
  ruby-json \
  ruby-irb \
  ruby-etc \
  ruby-ffi \
  libressl \
  libxml2 \
  ruby \
  wget \
  git

# Install dumb-init as our process supervisor
wget --quiet -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64
chmod +x /usr/local/bin/dumb-init
