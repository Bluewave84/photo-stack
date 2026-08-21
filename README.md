# photo-stack

A lightweight self-hosted Docker service for aligning and combining image sequences using Hugin's `align_image_stack` and Enfuse.

## Overview

```
images in /photos/input
        ↓
align_image_stack
        ↓
aligned TIFF files
        ↓
enfuse
        ↓
/photos/output/result.tif
```

## Modes

| Mode       | Description                                            |
| ---------- | ------------------------------------------------------ |
| `exposure` | Exposure-bracketed images; optimises field of view     |
| `handheld` | Handheld shots; contrast fusion with alignment         |
| `fixed`    | Fixed-camera shots; minimal alignment, contrast fusion |

The mode must be supplied as the first argument to the container.

## Usage

### Build the image

```bash
docker compose build
```

### Run

Place your input images (JPEG or TIFF) in `./photos/input/`, then run:

```bash
docker compose run --rm image-stack exposure
docker compose run --rm image-stack handheld
docker compose run --rm image-stack fixed
```

The result is written to `./photos/output/result.tif`.

## Directory layout

```
.
├── Dockerfile
├── docker-compose.yml
├── stack-images.sh
├── .gitignore
└── README.md
```

Host directories are mounted at runtime:

| Host path         | Container path   | Purpose       |
| ----------------- | ---------------- | ------------- |
| `./photos/input`  | `/photos/input`  | Input images  |
| `./photos/output` | `/photos/output` | Output result |

Temporary alignment files are written to `/tmp/image-stack` inside the container and are not persisted.

## Requirements

- Docker with Compose v2 (`docker compose`)
- No external focus-stacking tools (e.g. focus-stack) are included or required.
