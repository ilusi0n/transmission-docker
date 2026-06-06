# -----------------------------
# Stage 1: Builder (Alpine)
# -----------------------------
FROM alpine:3.23 AS builder

ARG TRANSMISSION_VERSION=4.0.5

RUN apk add --no-cache \
        build-base \
        cmake \
        ninja \
        pkgconf \
        curl-dev \
        curl \
        ca-certificates \
        git \
        file \
        fmt-dev \
        libevent-dev \
        openssl-dev \
        libpsl-dev \
        lz4-dev \
        gettext-dev \
        linux-headers \
        zlib-dev

WORKDIR /tmp/build

RUN curl -fsSL \
    "https://github.com/transmission/transmission/releases/download/${TRANSMISSION_VERSION}/transmission-${TRANSMISSION_VERSION}.tar.xz" \
    -o transmission.tar.xz && \
    tar -xf transmission.tar.xz

WORKDIR /tmp/build/transmission-${TRANSMISSION_VERSION}

ENV CMAKE_POLICY_VERSION_MINIMUM=3.5

RUN cmake -S . -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    #-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -DCMAKE_C_FLAGS_RELEASE="-O3 -fno-lto" \
    -DCMAKE_CXX_FLAGS_RELEASE="-O3 -fno-lto" \
    -DENABLE_DAEMON=ON \
    -DENABLE_CLI=ON \
    -DENABLE_WEB=ON \
    -DWITH_CRYPTO=openssl \
    -DMINIUPNPC_FOUND=OFF \
    -DUPNP=OFF \
    -DENABLE_NLS=OFF \
    -DENABLE_TESTS=OFF \
    -DENABLE_GTK=OFF \
    -DENABLE_QT=OFF \
    -DENABLE_SYSTEMD=OFF \
    -DENABLE_UTILS=ON \
    -DCMAKE_INSTALL_PREFIX=/usr/local

RUN cmake --build build -j"$(nproc)" && \
    cmake --install build

RUN find /usr/local -type f -exec file {} \; | \
    awk -F: '/ELF/ {print $1}' | \
    xargs -r strip --strip-unneeded


# -----------------------------
# Stage 2: Runtime (Alpine)
# -----------------------------
FROM alpine:3.23

RUN apk add --no-cache \
        tini \
        curl \
        jq \
        ca-certificates \
        libevent \
        openssl \
        lz4 \
        bash \
        zlib \
        libstdc++ \
        libgcc

RUN adduser -D -h /home/transmission -s /sbin/nologin transmission

COPY --from=builder /usr/local /usr/local

RUN mkdir -p /config /downloads /watch && \
    chown -R transmission:transmission \
        /config /downloads /watch

WORKDIR /config

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && \
    chown transmission:transmission /entrypoint.sh

EXPOSE 9091 51413/tcp 51413/udp

USER transmission

VOLUME ["/config", "/downloads", "/watch"]

STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -u "${RPC_USER:-transmission}:${RPC_PASS:-transmission}" \
      -s -o /dev/null -w "%{http_code}" \
      http://127.0.0.1:9091/transmission/rpc | \
      grep -Eq "200|409" || exit 1

ENTRYPOINT ["/sbin/tini", "--", "/bin/bash", "/entrypoint.sh"]
