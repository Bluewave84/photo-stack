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

| Mode       | Description                                                       | `--wExposure` | `--wSaturation` | `--wContrast` | `--hard-mask` |
| ---------- | ----------------------------------------------------------------- | ------------- | --------------- | ------------- | ------------- |
| `exposure` | Exposure-bracketed images; maximises dynamic range                | 1.0           | 0.2             | 0.0           | yes           |
| `handheld` | Handheld focus-stacking; selects sharpest pixels                  | 0.0           | 0.0             | 1.0           | yes           |
| `fixed`    | Fixed-camera focus-stacking; minimal alignment                    | 0.0           | 0.0             | 1.0           | yes           |
| `night`    | Night / architecture; balances exposure extremes and local detail | 1.0           | 0.5             | 0.5           | no            |

All modes output a 16-bit TIFF (`--depth=16`) to prevent colour banding in gradients and skies.
`--hard-mask` is enabled for focus-stacking modes and exposure brackets to suppress ghosting and sharpness halos; it is intentionally omitted for `night` so that luminance transitions blend softly.

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
docker compose run --rm image-stack night
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
