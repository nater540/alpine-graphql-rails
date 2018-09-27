# GraphQL Ruby

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Introduction](#introduction)
- [How do I use this thing?](#how-do-i-use-this-thing)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Introduction

Docker image based on Alpine Edge that contains the bare minimum to create a GraphQL Server using Ruby 2.5.1.

## How do I use this thing?

Add this to the top of your `Dockerfile`:

```
FROM nater540/graphql-ruby:latest
```

..Or use a specific tagged version:

```
FROM nater540/graphql-ruby:release-1.0.0
```

### Example Dockerfile

```docker
###################################################################################################
# Stage #1 - Create a container for installing gems & any necessary development packages.
# Important: Anything in this stage NOT copied into the final container will be DISCARDED!
###################################################################################################
FROM nater540/graphql-ruby:latest AS build-env

# This container image is setup for production builds by default
# NOTE: This argument is overridden inside `docker-compose.yml` for development!
ARG BUNDLE_WITHOUT='development test'

WORKDIR $INSTALL_PATH

COPY Gemfile Gemfile.lock ./

# Install necessary packages required for bundler to install the project dependencies
RUN apk --no-cache add \
  postgresql-dev \
  libxml2-dev \
  libxslt-dev \
  libffi-dev \
  build-base \
  ruby-dev

# Install gem dependencies and skip any groups specified via `BUNDLE_WITHOUT`
RUN bundle install --jobs 20 --without $BUNDLE_WITHOUT

###################################################################################################
# Stage #2 - Create the final container from the "pure" base image.
###################################################################################################
FROM nater540/graphql-ruby:latest AS final

# Copy the installed gems from the prior stage
COPY --from=build-env $GEM_HOME $GEM_HOME

ADD . .

EXPOSE 3000

# Uses the "dumb-init" process manager to ensure puma is gracefully started & stopped
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```
