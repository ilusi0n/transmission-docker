# -----------------------------
# Stage 1: Builder
# -----------------------------
FROM ubuntu:26.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ARG TRANSMISSION_VERSION=4.1.2

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        libfmt-dev \
        libevent-dev \
        libssl-dev \
        libcurl4-openssl-dev \
        libpsl-dev \
        liblz4-dev \
        libnatpmp-dev \
        zlib1g-dev \
        curl \
        #npm \
        ca-certificates

WORKDIR /tmp/build

RUN curl -fsSL \
    "https://github.com/transmission/transmission/releases/download/${TRANSMISSION_VERSION}/transmission-${TRANSMISSION_VERSION}.tar.xz" \
    -o transmission.tar.xz && \
    tar -xf transmission.tar.xz && \
    rm transmission.tar.xz

WORKDIR /tmp/build/transmission-${TRANSMISSION_VERSION}


RUN cmake -S . -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -DENABLE_DAEMON=ON \
    -DENABLE_CLI=ON \
    -DENABLE_WEB=ON \
    -DWITH_CRYPTO=openssl \
    #-DREBUILD_WEB=ON \
    -DENABLE_NLS=OFF \
    -DENABLE_TESTS=OFF \
    -DENABLE_GTK=OFF \
    -DENABLE_QT=OFF \
    -DENABLE_SYSTEMD=OFF \
    -DENABLE_UTILS=ON \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    && cmake --build build -j"$(nproc)" \
    && cmake --install build

RUN find /usr/local -type f -print0 | \
    xargs -0 file | \
    awk -F: '/ELF/ {print $1}' | \
    xargs -r strip --strip-unneeded

RUN rm -rf /tmp/build

# -----------------------------
# Stage 2: Runtime
# -----------------------------
FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tini \
        jq \
        curl \
        ca-certificates \
        libevent-2.1-7t64 \
        libssl3t64 \
        libcurl4t64 \
        liblz4-1 \
        zlib1g \
        libnatpmp1t64 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd \
        --create-home \
        --shell /usr/sbin/nologin \
        transmission

COPY --from=builder /usr/local /usr/local

RUN mkdir -p \
        /config \
        /downloads \
        /watch && \
    chown -R transmission:transmission \
        /config \
        /downloads \
        /watch

WORKDIR /config

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && \
    chown transmission:transmission /entrypoint.sh

EXPOSE 9091 51413 51413/udp

USER transmission

VOLUME ["/config", "/downloads", "/watch"]

STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -u "${RPC_USER:-transmission}:${RPC_PASS:-transmission}" \
       -s -o /dev/null -w "%{http_code}" \
       http://localhost:9091/transmission/rpc | grep -Eq "200|409" || exit 1

ENTRYPOINT ["/usr/bin/tini","--","/entrypoint.sh"]