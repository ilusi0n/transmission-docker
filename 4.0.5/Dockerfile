# -----------------------------
# Stage 1: Builder
# -----------------------------
FROM debian:trixie-slim AS builder
# Build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake pkg-config curl ca-certificates \
    libssl-dev libcurl4-openssl-dev libevent-dev liblz4-dev zlib1g-dev xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/build

# -----------------------------
# Build MiniUPnPc as static
# -----------------------------
ENV MINIUPNPC_VERSION=2.1
RUN curl -fsSL "https://miniupnp.tuxfamily.org/files/miniupnpc-${MINIUPNPC_VERSION}.tar.gz" -o miniupnpc.tar.gz \
    && tar -xf miniupnpc.tar.gz \
    && rm miniupnpc.tar.gz

WORKDIR /tmp/build/miniupnpc-${MINIUPNPC_VERSION}
# Build static library only
RUN make libminiupnpc.a
# Copy static library
RUN cp libminiupnpc.a /usr/local/lib/
# Copy all header files recursively
RUN find . -name '*.h' -exec cp {} /usr/local/include/ \;
# Update linker path
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/usr-local-lib.conf && ldconfig
    
    

# -----------------------------
# Build Transmission 4.0.5
# -----------------------------
ENV TRANSMISSION_VERSION=4.0.5
WORKDIR /tmp/build
RUN curl -fsSL "https://github.com/transmission/transmission/releases/download/${TRANSMISSION_VERSION}/transmission-${TRANSMISSION_VERSION}.tar.xz" -o transmission.tar.xz \
    && tar -xf transmission.tar.xz \
    && rm transmission.tar.xz

WORKDIR /tmp/build/transmission-${TRANSMISSION_VERSION}
RUN mkdir build && cd build && \
    cmake .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_DAEMON=ON \
      -DENABLE_CLI=ON \
      -DENABLE_WEB=ON \
      -DENABLE_NLS=OFF \
      -DENABLE_TESTS=OFF \
      -DENABLE_GTK=OFF \
      -DENABLE_QT=OFF \
      -DENABLE_UTILS=ON \
      -DUPNP_INCLUDE_DIR=/usr/local/include \
      -DUPNP_LIBRARY=/usr/local/lib/libminiupnpc.a \
      -DCMAKE_C_FLAGS="-O3 -pipe" \
      -DCMAKE_CXX_FLAGS="-O3 -pipe" \
      -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make -j$(nproc) && make install

# Strip binaries
RUN find /usr/local -type f -executable -exec strip --strip-all {} +

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
    && rm -rf /var/lib/apt/lists/*

# Non-root user
RUN useradd -m -s /usr/sbin/nologin transmission

# Copy Transmission from builder
COPY --from=builder /usr/local /usr/local
COPY --from=builder /etc/ld.so.conf.d/usr-local-lib.conf /etc/ld.so.conf.d/
RUN ldconfig

# Create required directories
RUN mkdir -p /config /downloads /watch && \
    chown -R transmission:transmission /config /downloads /watch

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && chown transmission:transmission /entrypoint.sh

# Expose RPC
EXPOSE 9091

USER transmission
VOLUME ["/config","/downloads","/watch"]
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -u "${RPC_USER:-transmission}:${RPC_PASS:-transmission}" \
       -s -o /dev/null -w "%{http_code}" \
       http://localhost:9091/transmission/rpc | grep -Eq "200|409" || exit 1

ENTRYPOINT ["/usr/bin/tini","--","/entrypoint.sh"]
    