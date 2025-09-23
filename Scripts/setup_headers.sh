#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

SRC_DIR="$PROJECT_ROOT/Sources/CubismFramework/src"
INCLUDE_DIR="$PROJECT_ROOT/Sources/CubismFramework/include"

# Default render type
RENDER_TYPE="Metal"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --render)
            RENDER_TYPE="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [--render <Metal|OpenGL|DirectX>]"
            exit 1
            ;;
    esac
done

echo "==> Cleaning old include directory"
rm -rf "$INCLUDE_DIR"
mkdir -p "$INCLUDE_DIR"

echo "==> Copying header files to include/ (Render type: $RENDER_TYPE)"

find "$SRC_DIR" -type f \( -name "*.h" -o -name "*.hpp"  -o -name "*.tpp" \) -print0 | while IFS= read -r -d '' file; do
    rel_path="${file#$SRC_DIR/}"

    if [[ "$rel_path" == Rendering/* ]]; then
        if [[ "$rel_path" =~ ^Rendering/[^/]+\.(h|hpp|tpp)$ || "$rel_path" =~ ^Rendering/$RENDER_TYPE/.*\.(h|hpp)$ ]]; then
            :
        else
            continue
        fi
    fi

    # Create destination directory
    dest_dir="$INCLUDE_DIR/$(dirname "$rel_path")"
    mkdir -p "$dest_dir"

    # Copy file (overwrite if exists)
    cp -f "$file" "$dest_dir/"
    echo "Copied $file -> $dest_dir/"
done

echo "==> Done, public headers are now in $INCLUDE_DIR"
