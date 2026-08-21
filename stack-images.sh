#!/usr/bin/env bash
set -euo pipefail

INPUT_DIR="/photos/input"
OUTPUT_DIR="/photos/output"
TMP_DIR="/tmp/image-stack"
OUTPUT_FILE="${OUTPUT_DIR}/result.tif"

MODE="${1:-}"

if [[ -z "$MODE" ]]; then
    echo "Usage: stack-images <mode>"
    echo "  Modes: exposure | handheld | fixed | night"
    exit 1
fi

case "$MODE" in
    exposure|handheld|fixed|night)
        ;;
    *)
        echo "Error: Unknown mode '${MODE}'. Valid modes are: exposure, handheld, fixed, night"
        exit 1
        ;;
esac

# Collect input images (JPEG and TIFF)
mapfile -t IMAGES < <(find "$INPUT_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.tif' -o -iname '*.tiff' \) | sort)

if [[ ${#IMAGES[@]} -eq 0 ]]; then
    echo "Error: No images found in ${INPUT_DIR}"
    exit 1
fi

echo "Mode: ${MODE}"
echo "Found ${#IMAGES[@]} input image(s)."

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR" "$OUTPUT_DIR"

# Build align_image_stack options based on mode
case "$MODE" in
    exposure)
        # Exposure bracketing: maximise dynamic range, suppress halos
        ALIGN_OPTS=(-a "${TMP_DIR}/aligned_" -m -x -c 30 -C)
        ENFUSE_OPTS=(--exposure-weight=1.0 --saturation-weight=0.2 --contrast-weight=0.0 --hard-mask --depth=16)
        ;;
    handheld)
        # Handheld focus-stacking: select sharpest pixels, hard boundaries essential
        ALIGN_OPTS=(-a "${TMP_DIR}/aligned_" -m -x -c 30 -C)
        ENFUSE_OPTS=(--exposure-weight=0.0 --saturation-weight=0.0 --contrast-weight=1.0 --contrast-window-size=5 --hard-mask --depth=16)
        ;;
    fixed)
        # Fixed-camera focus-stacking: minimal alignment, hard boundaries essential
        ALIGN_OPTS=(-a "${TMP_DIR}/aligned_" -c 10)
        ENFUSE_OPTS=(--exposure-weight=0.0 --saturation-weight=0.0 --contrast-weight=1.0 --contrast-window-size=5 --hard-mask --depth=16)
        ;;
    night)
        # Night / architecture: balance exposure and contrast for high-dynamic scenes
        ALIGN_OPTS=(-a "${TMP_DIR}/aligned_" -m -x -c 30 -C)
        ENFUSE_OPTS=(--exposure-weight=1.0 --saturation-weight=0.5 --contrast-weight=0.5 --depth=16)
        ;;
esac

echo "Aligning images..."
align_image_stack "${ALIGN_OPTS[@]}" "${IMAGES[@]}"

# Collect aligned TIFFs produced by align_image_stack
mapfile -t ALIGNED < <(find "$TMP_DIR" -maxdepth 1 -type f -name 'aligned_*.tif' | sort)

if [[ ${#ALIGNED[@]} -eq 0 ]]; then
    echo "Error: align_image_stack produced no output files."
    exit 1
fi

echo "Fusing ${#ALIGNED[@]} aligned image(s) with enfuse..."
enfuse "${ENFUSE_OPTS[@]}" --output="$OUTPUT_FILE" "${ALIGNED[@]}"

echo "Done. Result written to ${OUTPUT_FILE}"
