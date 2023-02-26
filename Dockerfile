# BUILD redisfab/redisearch:${VERSION}-${ARCH}-${OSNICK}

# Use a more specific base image
FROM docker.io/bitnami/minideb:bullseye AS base

# Set build arguments
ARG REDIS_VER=6.2.4
ARG ARCH=x64
ARG GIT_DESCRIBE_VERSION

# Install required system packages and dependencies
RUN install_packages acl ca-certificates curl gzip libc6 libssl1.1 procps tar && \
    apt-get update && apt-get upgrade -y && \
    rm -r /var/lib/apt/lists /var/cache/apt/archives

# Copy source code and scripts
COPY . /build
COPY prebuildfs /build/prebuildfs
COPY rootfs /build/rootfs

# Copy Redis binaries from another image
COPY --from=redisfab/redis:${REDIS_VER}-${ARCH}-bullseye-slim /usr/local/ /usr/local/

# Build RedisSearch and dependencies
RUN cd /build && \
    ./deps/readies/bin/getupdates && \
    ./deps/readies/bin/getpy2 && \
    ./system-setup.py && \
    /usr/local/bin/redis-server --version && \
    make fetch SHOW=1 && \
    make build SHOW=1 CMAKE_ARGS="-DGIT_DESCRIBE_VERSION=${GIT_DESCRIBE_VERSION}" && \
    ./deps/readies/bin/verify-python

# Install RedisSearch and RedisJSON modules
FROM redisfab/rejson:master-${ARCH}-bullseye AS json
# FROM redisfab/redis:${REDIS_VER}-${ARCH}-bullseye-slim AS redis

ENV LIBDIR /usr/lib/redis/modules/
RUN mkdir -p "$LIBDIR"

COPY --from=builder /build/build/redisearch.so* "$LIBDIR"
COPY --from=json /usr/lib/redis/modules/rejson.so* "$LIBDIR"

# Set container metadata
ENV BITNAMI_APP_NAME="redisearch" \
    BITNAMI_IMAGE_VERSION="${REDIS_VER}" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/redis/bin:$PATH"

EXPOSE 6379

USER 1001

# Set entrypoint and default command
ENTRYPOINT [ "/opt/bitnami/scripts/redis/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/redis/run.sh" ]
