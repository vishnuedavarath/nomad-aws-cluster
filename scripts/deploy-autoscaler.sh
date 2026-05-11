#!/bin/bash
set -euo pipefail

# Deploy the Nomad Autoscaler and configure its secrets
# Requires: NOMAD_ADDR and NOMAD_TOKEN (management) set
#
# Usage:
#   export NOMAD_ADDR=http://<server-ip>:4646
#   export NOMAD_TOKEN=<management-token>
#   ./scripts/deploy-autoscaler.sh <autoscaler-acl-token> <aws-region> <client-asg-name>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

AUTOSCALER_TOKEN="${1:?Usage: $0 <autoscaler-acl-token> <aws-region> <client-asg-name>}"
AWS_REGION="${2:?Usage: $0 <autoscaler-acl-token> <aws-region> <client-asg-name>}"
CLIENT_ASG_NAME="${3:?Usage: $0 <autoscaler-acl-token> <aws-region> <client-asg-name>}"

echo "==> Storing autoscaler secrets in Nomad Variables..."
nomad var put -force nomad/jobs/autoscaler \
  autoscaler_token="$AUTOSCALER_TOKEN" \
  aws_region="$AWS_REGION" \
  client_asg_name="$CLIENT_ASG_NAME"

echo "==> Deploying autoscaler job..."
BUCKET=$(cd "$REPO_ROOT" && terraform output -raw artifacts_bucket_name 2>/dev/null || echo "")
if [[ -z "$BUCKET" ]]; then
  echo "ERROR: Could not get artifacts bucket name from terraform output. Run 'terraform apply' first."
  exit 1
fi

BINARY_KEY=$(AWS_PAGER="" aws s3api list-objects-v2 \
  --bucket "$BUCKET" \
  --prefix "nomad-autoscaler/nomad-autoscaler-" \
  --query 'reverse(sort_by(Contents, &LastModified))[0].Key' \
  --output text 2>/dev/null || echo "")

if [[ -z "$BINARY_KEY" || "$BINARY_KEY" == "None" ]]; then
  LEGACY_KEY="nomad-autoscaler/nomad-autoscaler.zip"
  if AWS_PAGER="" aws s3api head-object --bucket "$BUCKET" --key "$LEGACY_KEY" >/dev/null 2>&1; then
    echo "==> No versioned autoscaler binary found; using legacy key: ${LEGACY_KEY}"
    BINARY_KEY="$LEGACY_KEY"
  else
    echo "ERROR: No autoscaler binary found in s3://${BUCKET}/nomad-autoscaler/."
    echo "Run './scripts/upload-autoscaler.sh' first."
    exit 1
  fi
fi

BINARY_URL="s3::https://s3.amazonaws.com/${BUCKET}/${BINARY_KEY}"
POLICIES_URL=$(cd "$REPO_ROOT" && terraform output -raw scaling_policies_url 2>/dev/null || echo "")

if [[ -z "$POLICIES_URL" ]]; then
  echo "ERROR: Could not get scaling policies URL from terraform output. Run 'terraform apply' first."
  exit 1
fi

echo "==> Using autoscaler binary: ${BINARY_KEY}"

nomad job run \
  -var="autoscaler_binary_url=${BINARY_URL}" \
  -var="scaling_policies_url=${POLICIES_URL}" \
  "$REPO_ROOT/nomad-jobs/autoscaler.nomad.hcl"

echo "==> Restarting autoscaler to pick up latest policies..."
nomad job restart autoscaler 2>/dev/null || true

echo "==> Autoscaler deployed. Check status with:"
echo "    nomad job status autoscaler"
echo ""
echo "    ASG: $CLIENT_ASG_NAME"
