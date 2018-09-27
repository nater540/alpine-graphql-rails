#!/usr/bin/env bash

set -ex

apk add --no-cache --virtual ruby_build_dep \
		autoconf \
		bison \
		bzip2 \
		bzip2-dev \
		ca-certificates \
		coreutils \
		dpkg-dev dpkg \
		gcc \
		gdbm-dev \
		glib-dev \
		libc-dev \
		libffi-dev \
		libressl \
		libressl-dev \
		libxml2-dev \
		libxslt-dev \
		linux-headers \
		make \
		ncurses-dev \
		procps \
		readline-dev \
		ruby \
		tar \
		xz \
		yaml-dev \
		zlib-dev

wget -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz" && \
  echo "${RUBY_DOWNLOAD_SHA256} *ruby.tar.xz" | sha256sum -c -

mkdir -p /usr/src/ruby && \
  tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1 && \
  rm ruby.tar.xz && \
  cd /usr/src/ruby

# Hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
{ \
  echo '#define ENABLE_PATH_CHECK 0'; \
  echo; \
  cat file.c; \
} > file.c.new && \
  mv file.c.new file.c

autoconf && \
  gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
  export ac_cv_func_isnan=yes ac_cv_func_isinf=yes

./configure \
	--build="${gnuArch}" \
	--disable-install-doc \
	--enable-shared && \
  make -j "$(nproc)" && \
	make install

runDeps="$( \
	scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
    | tr ',' '\n' \
    | sort -u \
    | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
)"

apk add --no-cache --virtual ruby_run_dep ${runDeps} \
  bzip2 \
  ca-certificates \
  libffi-dev \
  libressl-dev \
  procps \
  yaml-dev \
  zlib-dev

# Remove all of the installed ruby build dependencies
apk del ruby_build_dep

# Delete the ruby source code to free space
cd / && rm -r /usr/src/ruby

gem update --system "${RUBYGEMS_VERSION}"
gem install bundler --version "${BUNDLER_VERSION}" --force
rm -r /root/.gem/

# Disable documentation, install messages and suggestions when installing gems
echo "gem: --no-document --no-post-install-message --no-suggestions" >> /etc/gemrc
chmod uog+r /etc/gemrc
