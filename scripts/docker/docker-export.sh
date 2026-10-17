#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Export Docker images matching a regex pattern to individual tar files.

Options:
  -p, --pattern PATTERN  Regex pattern to match image name:tag (required)
  -o, --output DIR       Output directory (default: ./exported_images)
  -z, --compress         Compress exported images with xz (.tar.xz)
  -h, --help             Show this help message

Examples:
  $(basename "$0") -p nginx
  $(basename "$0") -p "redis:6\..*" -o ./backup
  $(basename "$0") -p "myapp.*" -z
EOF
    exit 1
}

PATTERN=""
OUTDIR="./exported_images"
COMPRESS=false

ARGS=$(getopt -o p:o:zh -l pattern:,output:,compress,help -n "$(basename "$0")" -- "$@")
eval set -- "$ARGS"

while true; do
    case "$1" in
        -p|--pattern) PATTERN="$2"; shift 2 ;;
        -o|--output) OUTDIR="$2"; shift 2 ;;
        -z|--compress) COMPRESS=true; shift ;;
        -h|--help) usage ;;
        --) shift; break ;;
        *) usage ;;
    esac
done

[[ -z "$PATTERN" ]] && usage

mkdir -p "$OUTDIR"

mapfile -t IMAGES < <(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E "$PATTERN" || true)

if [[ ${#IMAGES[@]} -eq 0 ]]; then
    echo "No images matched pattern: $PATTERN"
    exit 0
fi

echo "Matched ${#IMAGES[@]} images, exporting to $OUTDIR ..."

for img in "${IMAGES[@]}"; do
    safe_name=$(echo "$img" | tr '/:' '__')

    if [[ "$COMPRESS" == true ]]; then
        tarball="$OUTDIR/${safe_name}.tar.xz"
    else
        tarball="$OUTDIR/${safe_name}.tar"
    fi

    if [[ -f "$tarball" ]]; then
        read -r -p "File $tarball already exists. Overwrite? [y/N]: " answer
        if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
            echo "  Skipping $img"
            continue
        fi
    fi

    if [[ "$COMPRESS" == true ]]; then
        echo "  Saving (compress) $img -> $tarball"
        docker save "$img" | xz -c > "$tarball"
    else
        echo "  Saving $img -> $tarball"
        docker save "$img" -o "$tarball"
    fi
done

echo "Done."
