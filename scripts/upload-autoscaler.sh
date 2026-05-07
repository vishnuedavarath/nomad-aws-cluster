#!/usr/bin/env bash
# Upload a nomad-autoscaler binary to S3 artifacts bucket.
# Usage:
#   ./scripts/upload-autoscaler.sh                              # downloads latest official release (default)
#   ./scripts/upload-autoscaler.sh --local                      # uses local build from ~/projects/hashicorp/nomad-autoscaler/.bin
#   ./scripts/upload-autoscaler.sh /path/to/nomad-autoscaler    # uses specified binary
set -euo pipefail

LOCAL_BUILD="$HOME/projects/hashicorp/nomad-autoscaler/bin/nomad-autoscaler"

BUCKET=$(terraform output -raw artifacts_bucket_name 2>/dev/null || echo "")
if [[ -z "$BUCKET" ]]; then
  echo "ERROR: Could not determine artifacts bucket. Run 'terraform apply' first."
  exit 1
fi

BINARY_PATH="${1:-}"
TMPDIR_CLEAN=$(mktemp -d)
trap 'rm -rf "$TMPDIR_CLEAN"' EXIT

if [[ "$BINARY_PATH" == "--local" ]]; then
  if [[ -f "$LOCAL_BUILD" ]]; then
    echo "Using local build: $LOCAL_BUILD"
    zip -j "${TMPDIR_CLEAN}/nomad-autoscaler.zip" "$LOCAL_BUILD"
  else
    echo "ERROR: No binary found at $LOCAL_BUILD"
    exit 1
  fi
elif [[ -n "$BINARY_PATH" && "$BINARY_PATH" != "--latest" ]]; then
  echo "Using provided binary: $BINARY_PATH"
  zip -j "${TMPDIR_CLEAN}/nomad-autoscaler.zip" "$BINARY_PATH"
else
  # Default: download latest official release
  echo "Downloading latest release..."
  VERSION=$(curl -s https://releases.hashicorp.com/nomad-autoscaler/ | grep -oE 'nomad-autoscaler/[0-9]+\.[0-9]+\.[0-9]+' | head -1 | cut -d/ -f2)
  echo "Latest version: $VERSION"
  curl -sL "https://releases.hashicorp.com/nomad-autoscaler/${VERSION}/nomad-autoscaler_${VERSION}_linux_amd64.zip" \
    -o "${TMPDIR_CLEAN}/nomad-autoscaler.zip"
fi

echo "Uploading to s3://${BUCKET}/nomad-autoscaler/nomad-autoscaler.zip ..."
aws s3 cp "${TMPDIR_CLEAN}/nomad-autoscaler.zip" "s3://${BUCKET}/nomad-autoscaler/nomad-autoscaler.zip"

echo "Done. Redeploy the autoscaler job to pick up the new binary."
