##############################################################################################################
# Create the base container
##############################################################################################################
FROM alpine:3.8 AS base
# FROM alpine:edge AS base
LABEL maintainer="Nate Strandberg <nater540@gmail.com>"

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
    BUNDLE_BIN="$GEM_HOME/bin" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH

# RUN addgroup -g 1000 -S app && \
#     adduser -u 1000 -S app -G app

# RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" && chown -R app:app "$GEM_HOME" "$BUNDLE_BIN"
RUN mkdir -p "${GEM_HOME}" "${BUNDLE_BIN}" && chmod 777 "${GEM_HOME}" "${BUNDLE_BIN}"

ENV INSTALL_PATH /app/current
WORKDIR $INSTALL_PATH

COPY ./scripts /scripts

RUN apk --no-cache add bash

# RUN /scripts/ruby.sh
RUN /scripts/base_packages.sh

##############################################################################################################
# Compile libgraphqlparser inside it's own container
##############################################################################################################
FROM base AS libgraphqlparser
RUN /scripts/graphql_parser.sh

##############################################################################################################
# Create the final container image from the original base container
##############################################################################################################
FROM base

COPY --from=libgraphqlparser /usr/local/include/graphqlparser /usr/local/include/graphqlparser
COPY --from=libgraphqlparser /usr/local/lib/libgraphqlparser.so /usr/local/lib/libgraphqlparser.so

# Use the "dumb-init" process manager
ENTRYPOINT ["/usr/local/bin/dumb-init", "--rewrite", "15:3", "--"]
