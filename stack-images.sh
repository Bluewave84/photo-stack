#!/usr/bin/env bash
set -euo pipefail

INPUT_DIR="/photos/input"
OUTPUT_DIR="/photos/output"
TMP_DIR="/tmp/image-stack"
OUTPUT_FILE="${OUTPUT_DIR}/result.tif"

MODE="${1:-}"

if [[ -z "$MODE" ]]; then
    echo "Usage: stack-images <mode>"
    echo "  Modes: exposure | handheld | fixed"
    exit 1
fi

case "$MODE" in
    exposure|handheld|fixed)
        ;;
    *)
        echo "Error: Unknown mode '${MODE}'. Valid modes are: exposure, handheld, fixed"
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
        # Exposure bracketing: optimise field of view and radial distortion
        ALIGN_OPTS=(-a "${TMP_DIR}/aligned_" -m -x -c 30 -C)
        ENFUSE_OPTS=(--exposure-weight=1 --saturation-weight=0.2 --contrast-weight=0)
        ;;
    handheld)
        # Handheld shots: also correct for translation and rotation
        ALIGN_OPTS=(-a "${TMP_DIR}/aligned_" -m -x -c 30 -C)
        ENFUSE_OPTS=(--exposure-weight=0 --saturation-weight=0.2 --contrast-weight=1)
        ;;
    fixed)
        # Fixed camera: minimal alignment, no field-of-view correction
        ALIGN_OPTS=(-a "${TMP_DIR}/aligned_" -c 10)
        ENFUSE_OPTS=(--exposure-weight=0 --saturation-weight=0.2 --contrast-weight=1)
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
