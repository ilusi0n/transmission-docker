# -----------------------------
# Stage 1: Builder
# -----------------------------
FROM debian:trixie-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive
ARG TRANSMISSION_VERSION=4.0.5

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        pkg-config \
        curl \
        ca-certificates \
        libssl-dev \
        libcurl4-openssl-dev \
        libevent-dev \
        liblz4-dev \
        libnatpmp-dev \
        libpsl-dev \
        zlib1g-dev \
        xz-utils \
        file \
        ninja-build \
        npm \
    && rm -rf /var/lib/apt/lists/*

# -----------------------
# Build Transmission
# -----------------------

WORKDIR /tmp/build

RUN curl -fsSL "https://github.com/transmission/transmission/releases/download/${TRANSMISSION_VERSION}/transmission-${TRANSMISSION_VERSION}.tar.xz" -o transmission.tar.xz \
    && tar -xf transmission.tar.xz \
    && rm transmission.tar.xz

WORKDIR /tmp/build/transmission-${TRANSMISSION_VERSION}

# Build
RUN cmake -S . -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -D ENABLE_DAEMON=ON \
    -D ENABLE_CLI=ON \
    -D ENABLE_WEB=ON \
    -D WITH_CRYPTO=openssl \
    -D REBUILD_WEB=ON \
    -D ENABLE_NLS=OFF \
    -D ENABLE_TESTS=OFF \
    -D ENABLE_GTK=OFF \
    -D ENABLE_QT=OFF \
    -D ENABLE_SYSTEMD=OFF \
    -D ENABLE_UTILS=ON \
    -D CMAKE_C_FLAGS="${CMAKE_C_FLAGS} -O3 -ffat-lto-objects" \
    -D CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -O3 -ffat-lto-objects" \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    && cmake --build build -j"$(nproc)" \
    && cmake --install build

# Strip ELF binaries
RUN find /usr/local -type f -print0 | \
    xargs -0 file | \
    awk -F: '/ELF/ {print $1}' | \
    xargs -r strip --strip-unneeded

RUN rm -rf /tmp/build

# -----------------------------
# Stage 2: Runtime
# -----------------------------
FROM debian:trixie-slim

# Runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libevent-2.1-7 \
    libssl3 \
    libcurl4 \
    liblz4-1 \
    zlib1g \
    tini \
    jq \
    ca-certificates \
    curl \
    libnatpmp1t64 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /usr/sbin/nologin transmission

# Copy built binaries
COPY --from=builder /usr/local /usr/local

# Create required directories
RUN mkdir -p /config /downloads /watch && \
    chown -R transmission:transmission /config /downloads /watch

WORKDIR /config

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    chown transmission:transmission /entrypoint.sh

EXPOSE 9091 51413 51413/udp

USER transmission

VOLUME ["/config","/downloads","/watch"]

STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -u "${RPC_USER:-transmission}:${RPC_PASS:-transmission}" \
       -s -o /dev/null -w "%{http_code}" \
       http://localhost:9091/transmission/rpc | grep -Eq "200|409" || exit 1

ENTRYPOINT ["/usr/bin/tini","--","/entrypoint.sh"]
    
    