#!/usr/bin/env bash
# Run this ONCE before `terraform apply`, or whenever requirements.txt changes.
# It builds the Pillow layer and uploads it to S3 so Terraform never has to
# do a slow local upload (which causes signature expiry errors).
#
# Usage:
#   ./build_layer.sh <s3-bucket-name>
#   ./build_layer.sh hehe-lambda-artifacts

set -e

ARTIFACTS_BUCKET="${1:-hehe-lambda-artifacts}"
LAYER_S3_KEY="pillow-layer.zip"
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

echo "▶ Zipping layer..."
cd "$LAYER_DIR"
zip -rq "$OUTPUT_ZIP" python

echo "▶ Creating S3 bucket if it doesn't exist..."
aws s3 mb "s3://$ARTIFACTS_BUCKET" --region us-east-1 2>/dev/null || true

echo "▶ Uploading to s3://$ARTIFACTS_BUCKET/$LAYER_S3_KEY ..."
aws s3 cp "$OUTPUT_ZIP" "s3://$ARTIFACTS_BUCKET/$LAYER_S3_KEY"

echo ""
echo "✓ Done! Now run:  terraform apply"
