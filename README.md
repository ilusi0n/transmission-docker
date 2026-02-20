# transmission-docker

Repository containing Dockerfiles for multiple versions of [Transmission](https://transmissionbt.com/), built from source with optimized flags. Includes daemon, CLI, and web UI.
Some images are pre-built and available on GitHub Container Registry

## Features

- Transmission daemon, CLI, and Web UI  
- Non-root container execution with Tini  
- Volumes `/config`, `/downloads` and `/watch`
- Dynamic configuration via environment variables

## Image Registry

Images are published to:

`ghcr.io/ilusi0n/transmission-docker/transmission`

## Available Tags

Each build produces the following tags:

```
ghcr.io/ilusi0n/transmission-docker/transmission:<version>-<base>-latest
ghcr.io/ilusi0n/transmission-docker/transmission:<version>-<base>-<commit-sha>
```

### Example

```
ghcr.io/ilusi0n/transmission-docker/transmission:4.1.1-ubuntu-a87e78f
ghcr.io/ilusi0n/transmission-docker/transmission:4.1.1-ubuntu-latest
```

## Usage
Here are some snippets to get you going

### docker-compose

```
services:
  transmission:
    image: ghcr.io/ilusi0n/transmission-docker/transmission:4.1.1-ubuntu
    container_name: transmission
    user: 1000:1000
    volumes:
      - ./config:/config
      - ./downloads:/downloads
      - ./watch:/watch
    ports:
      - 58875:58875
      - 58875:58875/udp
    restart: unless-stopped
```

Create a `.env` with your Transmission settings:
```env
RPC_USER=RPC_USERNAME
RPC_PASS=RPC_PASSWORD
PEER_PORT=58875
WATCH_DIR_ENABLED=false
WATCH_DIR=/watch
DHT_ENABLED=false
PEER_PORT=58875
CACHE_SIZE_MB=128
PEX_ENABLED=false
LPD_ENABLED=false
UTP_ENABLED=false
RENAME_PARTIAL_FILES=false
PEX_ENABLED=false
RATIO_LIMIT=1
RATIO_LIMIT_ENABLED=true
START_ADDED_TORRENTS=false
UTP_ENABLED=true
LPD_ENABLED=false
DOWNLOAD_QUEUE_ENABLED=false
DOWNLOAD_QUEUE_SIZE=15
PREALLOCATION=0
```

### Or Build the image yourself

```
docker build -t transmission:4.1.1-ubuntu ./4.1.1-ubuntu
```

## License

MIT License - see LICENSE file for details