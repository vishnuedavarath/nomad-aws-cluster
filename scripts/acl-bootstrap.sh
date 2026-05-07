#!/bin/bash
set -euo pipefail

# Bootstrap Nomad ACL system
# Run this ONCE after the cluster is healthy.
# Requires: nomad CLI installed locally, NOMAD_ADDR set to a server.
#
# Usage:
#   export NOMAD_ADDR=http://<server-ip>:4646
#   export AWS_REGION=us-east-1
#   export SSM_PREFIX=/nomad-cluster/acl
#   ./scripts/acl-bootstrap.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_REGION="${AWS_REGION:-us-east-1}"
SSM_PREFIX="${SSM_PREFIX:-/nomad-cluster/acl}"

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI is required. Please install/configure aws CLI and retry."
  exit 1
fi

if ! command -v nomad >/dev/null 2>&1; then
  echo "nomad CLI is required. Please install/configure nomad CLI and retry."
  exit 1
fi

echo "==> Bootstrapping Nomad ACL system..."
BOOTSTRAP_OUTPUT=$(nomad acl bootstrap 2>&1) || {
  if echo "$BOOTSTRAP_OUTPUT" | grep -q "already done"; then
    echo "ACL bootstrap was already performed on this cluster."
    echo ""
    echo "To store existing tokens in SSM, run:"
    echo "  aws ssm put-parameter --region $AWS_REGION --name $SSM_PREFIX/management-token --type SecureString --value '<your-management-token>' --overwrite"
    echo "  aws ssm put-parameter --region $AWS_REGION --name $SSM_PREFIX/operator-token --type SecureString --value '<your-operator-token>' --overwrite"
    echo "  aws ssm put-parameter --region $AWS_REGION --name $SSM_PREFIX/autoscaler-token --type SecureString --value '<your-autoscaler-token>' --overwrite"
    echo ""
    echo "To create new operator/autoscaler tokens (requires NOMAD_TOKEN set to management token):"
    echo "  nomad acl token create -name=operator -policy=operator -type=client"
    echo "  nomad acl token create -name=autoscaler -policy=autoscaler -type=client"
    exit 1
  fi
  echo "$BOOTSTRAP_OUTPUT"
  exit 1
}

echo "$BOOTSTRAP_OUTPUT"

# Extract the secret ID (management token)
MGMT_TOKEN=$(echo "$BOOTSTRAP_OUTPUT" | grep "Secret ID" | awk '{print $4}')

echo ""
echo "==> Management token: $MGMT_TOKEN"
echo ""
echo "Store this token securely! It cannot be retrieved again."
echo ""
echo "To use it:"
echo "  export NOMAD_TOKEN=$MGMT_TOKEN"
echo ""
echo "==> Creating operator policy and token..."

export NOMAD_TOKEN="$MGMT_TOKEN"

# Create a node-read policy (for autoscaler)
nomad acl policy apply \
  -description "Autoscaler policy - read jobs and scale" \
  autoscaler \
  "$SCRIPT_DIR/policies/autoscaler.hcl"

# Create an operator policy (day-to-day management without full management token)
nomad acl policy apply \
  -description "Operator policy - submit jobs, read nodes" \
  operator \
  "$SCRIPT_DIR/policies/operator.hcl"

echo ""
echo "==> Creating operator token..."
OPERATOR_OUTPUT=$(nomad acl token create \
  -name="operator" \
  -policy=operator \
  -type=client)

echo "$OPERATOR_OUTPUT"
OPERATOR_TOKEN=$(echo "$OPERATOR_OUTPUT" | grep "Secret ID" | awk '{print $4}')

echo ""
echo "==> Creating autoscaler token..."
AUTOSCALER_OUTPUT=$(nomad acl token create \
  -name="autoscaler" \
  -policy=autoscaler \
  -type=client)

echo "$AUTOSCALER_OUTPUT"
AUTOSCALER_TOKEN=$(echo "$AUTOSCALER_OUTPUT" | grep "Secret ID" | awk '{print $4}')

echo ""
echo "==> Storing tokens in AWS SSM Parameter Store..."
aws ssm put-parameter \
  --region "$AWS_REGION" \
  --name "$SSM_PREFIX/management-token" \
  --type "SecureString" \
  --value "$MGMT_TOKEN" \
  --overwrite >/dev/null

aws ssm put-parameter \
  --region "$AWS_REGION" \
  --name "$SSM_PREFIX/operator-token" \
  --type "SecureString" \
  --value "$OPERATOR_TOKEN" \
  --overwrite >/dev/null

aws ssm put-parameter \
  --region "$AWS_REGION" \
  --name "$SSM_PREFIX/autoscaler-token" \
  --type "SecureString" \
  --value "$AUTOSCALER_TOKEN" \
  --overwrite >/dev/null

echo ""
echo "==> ACL bootstrap complete."
echo "Tokens saved in SSM under prefix: $SSM_PREFIX"
echo ""
echo "To load operator token locally:"
echo "  export NOMAD_TOKEN=\$(aws ssm get-parameter --region $AWS_REGION --name $SSM_PREFIX/operator-token --with-decryption --query Parameter.Value --output text)"
