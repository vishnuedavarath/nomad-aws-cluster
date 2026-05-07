#!/bin/bash
set -euo pipefail

# Deploy the Nomad Autoscaler and configure its secrets
# Requires: NOMAD_ADDR and NOMAD_TOKEN (management) set
#
# Usage:
#   export NOMAD_ADDR=http://<server-ip>:4646
#   export NOMAD_TOKEN=<management-token>
#   ./scripts/deploy-autoscaler.sh <autoscaler-acl-token> <aws-region> <client-asg-name> [min] [max]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

AUTOSCALER_TOKEN="${1:?Usage: $0 <autoscaler-acl-token> <aws-region> <client-asg-name> [min] [max]}"
AWS_REGION="${2:?Usage: $0 <autoscaler-acl-token> <aws-region> <client-asg-name> [min] [max]}"
CLIENT_ASG_NAME="${3:?Usage: $0 <autoscaler-acl-token> <aws-region> <client-asg-name> [min] [max]}"
CLIENT_MIN="${4:-1}"
CLIENT_MAX="${5:-5}"

echo "==> Storing autoscaler secrets in Nomad Variables..."
nomad var put -force nomad/jobs/autoscaler \
  autoscaler_token="$AUTOSCALER_TOKEN" \
  aws_region="$AWS_REGION" \
  client_asg_name="$CLIENT_ASG_NAME" \
  client_min="$CLIENT_MIN" \
  client_max="$CLIENT_MAX"

echo "==> Deploying autoscaler job..."
BINARY_URL=$(cd "$REPO_ROOT" && terraform output -raw autoscaler_binary_url 2>/dev/null || echo "")
if [[ -n "$BINARY_URL" ]]; then
  nomad job run -var="autoscaler_binary_url=${BINARY_URL}" "$REPO_ROOT/nomad-jobs/autoscaler.nomad.hcl"
else
  echo "ERROR: Could not get S3 URL from terraform output. Run 'terraform apply' first."
  exit 1
fi

echo "==> Autoscaler deployed. Check status with:"
echo "    nomad job status autoscaler"
echo ""
echo "    ASG: $CLIENT_ASG_NAME (min=$CLIENT_MIN, max=$CLIENT_MAX)"
