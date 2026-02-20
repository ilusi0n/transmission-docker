# -----------------------------
# Stage 1: Builder
# -----------------------------
    FROM ubuntu:24.04 AS builder

    ENV DEBIAN_FRONTEND=noninteractive
    ENV TRANSMISSION_VERSION=4.1.1
    
    # Install build dependencies
    RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        pkg-config \
        curl \
        ca-certificates \
        libssl-dev \
        libcurl4-openssl-dev \
        libevent-dev \
        liblz4-dev \
        libminiupnpc-dev \
        libnatpmp-dev \
        libpsl-dev \
        libsystemd-dev \
        zlib1g-dev \
        xz-utils \
        file \
        && rm -rf /var/lib/apt/lists/*

    
    WORKDIR /tmp/build
    
    # -----------------------
    # Build Transmission
    # -----------------------
    
    RUN curl -fsSL \
        "https://github.com/transmission/transmission/releases/download/${TRANSMISSION_VERSION}/transmission-${TRANSMISSION_VERSION}.tar.xz" \
        -o transmission.tar.xz \
        && tar -xf transmission.tar.xz \
        && rm transmission.tar.xz
    
    WORKDIR /tmp/build/transmission-${TRANSMISSION_VERSION}
    
    RUN mkdir build && cd build && \
        cmake .. \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
          -DENABLE_DAEMON=ON \
          -DENABLE_CLI=ON \
          -DENABLE_WEB=ON \
          -DENABLE_NLS=OFF \
          -DENABLE_TESTS=OFF \
          -DENABLE_GTK=OFF \
          -DENABLE_QT=OFF \
          -DENABLE_SYSTEMD=OFF \
          -DENABLE_UTILS=ON \
          -DCMAKE_C_FLAGS="-O3 -fno-plt -flto" \
          -DCMAKE_CXX_FLAGS="-O3 -fno-plt -flto" \
          -DCMAKE_INSTALL_PREFIX=/usr/local && \
        make -j"$(nproc)" && \
        make install
    
    # Strip only actual ELF binaries (safe)
    RUN find /usr/local -type f -print0 | \
        xargs -0 file | \
        awk -F: '/ELF/ {print $1}' | \
        xargs -r strip --strip-unneeded
    
    
    # -----------------------------
    # Stage 2: Runtime
    # -----------------------------
    FROM ubuntu:24.04
    
    ENV DEBIAN_FRONTEND=noninteractive
    
    # Install runtime dependencies only
    RUN apt-get update && apt-get install -y --no-install-recommends \
        libevent-2.1-7 \
        libssl3 \
        libcurl4 \
        liblz4-1 \
        libminiupnpc17 \
        libnatpmp1 \
        zlib1g \
        tini \
        jq \
        ca-certificates \
        curl \
        && rm -rf /var/lib/apt/lists/*

    
    # Create non-root user
    RUN useradd -m -s /usr/sbin/nologin transmission
    
    # Copy built binaries
    COPY --from=builder /usr/local /usr/local
    
    RUN ldconfig
    
    # Create required directories
    RUN mkdir -p /config /downloads /watch && \
        chown -R transmission:transmission /config /downloads /watch
    
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
    