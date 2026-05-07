#!/bin/bash
set -euo pipefail

# Load operator token from AWS SSM Parameter Store.
# Usage:
#   eval "$(./scripts/load-operator-token.sh us-east-1 /nomad-cluster/acl)"

AWS_REGION="${1:-us-east-1}"
SSM_PREFIX="${2:-/nomad-cluster/acl}"
PARAM_NAME="$SSM_PREFIX/operator-token"

TOKEN=$(aws ssm get-parameter \
  --region "$AWS_REGION" \
  --name "$PARAM_NAME" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text)

printf 'export NOMAD_TOKEN=%q\n' "$TOKEN"
