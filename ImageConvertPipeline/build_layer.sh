#!/usr/bin/env bash
# Run this ONCE before `terraform apply` to pre-build the Pillow Lambda layer.
# Re-run it only if you change lambda_src/requirements.txt.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAYER_DIR="/tmp/lambda_layer"
OUTPUT_ZIP="$SCRIPT_DIR/modules/lambda/lambda_layer.zip"
REQUIREMENTS="$SCRIPT_DIR/lambda_src/requirements.txt"

echo "▶ Cleaning previous build..."
rm -rf "$LAYER_DIR"
mkdir -p "$LAYER_DIR/python"

echo "▶ Installing packages for Lambda (manylinux / Python 3.12)..."
pip install \
  --quiet \
  --platform manylinux2014_x86_64 \
  --implementation cp \
  --python-version 3.12 \
  --only-binary=:all: \
  --target "$LAYER_DIR/python" \
  -r "$REQUIREMENTS"

echo "▶ Zipping layer → $OUTPUT_ZIP"
cd "$LAYER_DIR"
zip -rq "$OUTPUT_ZIP" python

echo "✓ Layer built: $OUTPUT_ZIP"
echo "  You can now run: terraform apply"
