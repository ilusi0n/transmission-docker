# transmission-docker

Dockerized builds of [Transmission](https://transmissionbt.com/) for multiple versions, compiled from source with optimized flags. Includes daemon, CLI, and web UI.

## Features

- Transmission daemon, CLI, and Web UI  
- Optimized compilation for performance (`-O3 -march=native -pipe`)  
- Non-root container execution with Tini  
- Configurable volumes: `/config`, `/downloads`, `/watch`

