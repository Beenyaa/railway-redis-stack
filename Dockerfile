# BUILD redisfab/redisearch:${VERSION}-${ARCH}-${OSNICK}

ARG REDIS_VER=6.2.4
ARG OSNICK=bullseye
ARG OS=debian:bullseye-slim
ARG ARCH=amd64 # change from x64 to amd64
ARG GIT_DESCRIBE_VERSION

FROM redisfab/redis:${REDIS_VER}-${ARCH}-${OSNICK} AS redis
FROM ${OS} AS builder

RUN echo "Building for ${OSNICK} (${OS}) for ${ARCH}"

WORKDIR /build
COPY --from=redis /usr/local/ /usr/local/
COPY . .

RUN ./deps/readies/bin/getupdates && \
    ./deps/readies/bin/getpy2 && \
    ./system-setup.py && \
    /usr/local/bin/redis-server --version && \
    make fetch SHOW=1 && \
    make build SHOW=1 CMAKE_ARGS="-DGIT_DESCRIBE_VERSION=${GIT_DESCRIBE_VERSION}"

ARG TEST=0

RUN if [ "$TEST" = "1" ]; then make test; fi

FROM redisfab/rejson:master-${ARCH}-${OSNICK} AS json
FROM redisfab/redis:${REDIS_VER}-${ARCH}-${OSNICK}

# Expose port 6379
EXPOSE 6379

USER 1001

WORKDIR /data

ENV LIBDIR /usr/lib/redis/modules/
RUN mkdir -p "$LIBDIR"

COPY --from=builder /build/build/redisearch.so* "$LIBDIR"
COPY --from=json /usr/lib/redis/modules/rejson.so* "$LIBDIR"

CMD ["redis-server", "--loadmodule", "/usr/lib/redis/modules/redisearch.so", "--loadmodule", "/usr/lib/redis/modules/rejson.so"]
