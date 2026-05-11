# Nomad AWS Cluster

Terraform-managed HashiCorp Nomad cluster on AWS with autoscaling client nodes.

## Architecture

- **3 Nomad server nodes** (fixed ASG) — form the consensus quorum
- **N Nomad client/worker nodes** (autoscaled ASG, spot instances) — run workloads
- **Nomad Autoscaler** — runs as a Nomad job, scales client ASG based on cluster resource allocation
- **ACL enabled** — management, operator, and autoscaler tokens stored in AWS SSM Parameter Store

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured (`~/.aws/credentials` or env vars)
- [Nomad CLI](https://developer.hashicorp.com/nomad/install)
- [Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) (`brew install --cask session-manager-plugin`)

## Quick Start

### 1. Set credentials

```bash
# Option A: Source .env file
cp .env.example .env  # edit with your AWS keys
source .env

# Option B: Use ~/.aws/credentials (auto-detected)
```

### 2. Bootstrap remote state (one-time)

```bash
cd state/
terraform init
terraform apply
cd ..
```

### 3. Deploy infrastructure

```bash
terraform init
terraform apply
```

### 4. Connect to the cluster

Use SSM port forwarding (no open ports required):

```bash
# Get a server instance ID
INSTANCE_ID=$(aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:NomadRole,Values=server" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' --output text)

# Port-forward Nomad API to localhost:4646
aws ssm start-session --target "$INSTANCE_ID" --region us-east-1 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["4646"],"localPortNumber":["4646"]}'
```

In a second terminal:

```bash
export NOMAD_ADDR=http://localhost:4646
nomad status
```

### 5. Bootstrap ACL (one-time, after cluster is healthy)

```bash
export NOMAD_ADDR=http://localhost:4646
./scripts/acl-bootstrap.sh
```

This creates management, operator, and autoscaler tokens and stores them in AWS SSM Parameter Store under `/nomad-cluster/acl/`.

### 6. Load operator token (any future session)

```bash
eval "$(./scripts/load-operator-token.sh)"
```

Or manually:

```bash
export NOMAD_TOKEN=$(aws ssm get-parameter --region us-east-1 \
  --name /nomad-cluster/acl/operator-token \
  --with-decryption --query Parameter.Value --output text)
```

### 7. Upload autoscaler binary artifact

The autoscaler job downloads its binary from S3. Upload it first:

```bash
./scripts/upload-autoscaler.sh
```

Optional:

```bash
# Use a local build
./scripts/upload-autoscaler.sh --local

# Or provide an explicit binary path
./scripts/upload-autoscaler.sh /path/to/nomad-autoscaler
```

The upload script stores binaries under versioned keys like
`nomad-autoscaler/nomad-autoscaler-<hash>.zip`.
The deploy script automatically picks the latest uploaded binary.

### 8. Configure scaling policies and publish changes

Scaling policies live in the `scaling-policies/` directory.

```bash
# Example: edit baseline policy
$EDITOR scaling-policies/cluster.hcl

# Publish policy changes (zips directory and uploads to S3)
terraform apply
```

Any new or changed `.hcl` file in `scaling-policies/` is included automatically.

### 9. Deploy autoscaler

```bash
export NOMAD_TOKEN=$(aws ssm get-parameter --region us-east-1 \
  --name /nomad-cluster/acl/management-token \
  --with-decryption --query Parameter.Value --output text)

AUTOSCALER_TOKEN=$(aws ssm get-parameter --region us-east-1 \
  --name /nomad-cluster/acl/autoscaler-token \
  --with-decryption --query Parameter.Value --output text)

./scripts/deploy-autoscaler.sh "$AUTOSCALER_TOKEN" us-east-1 nomad-cluster-client-asg
```

If you update policies later:

```bash
terraform apply
./scripts/deploy-autoscaler.sh "$AUTOSCALER_TOKEN" us-east-1 nomad-cluster-client-asg
```

### 10. Verify artifacts when troubleshooting

```bash
BUCKET=$(terraform output -raw artifacts_bucket_name)
aws s3 ls "s3://${BUCKET}/nomad-autoscaler/"
aws s3 ls "s3://${BUCKET}/scaling-policies/"

# Show the latest uploaded autoscaler binary key
AWS_PAGER="" aws s3api list-objects-v2 \
  --bucket "$BUCKET" \
  --prefix "nomad-autoscaler/nomad-autoscaler-" \
  --query 'reverse(sort_by(Contents, &LastModified))[0].Key' \
  --output text
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `us-east-1` | AWS region |
| `project_name` | `nomad-cluster` | Name prefix for all resources |
| `availability_zones` | `[us-east-1a, b, c]` | AZs for subnet distribution |
| `server_instance_type` | `t3.small` | EC2 instance type for servers |
| `client_instance_type` | `t3.medium` | EC2 instance type for clients |
| `client_count` | `2` | Desired number of client nodes |
| `client_min` | `1` | Minimum client nodes (autoscaler floor) |
| `client_max` | `5` | Maximum client nodes (autoscaler ceiling) |
| `nomad_token_ssm_prefix` | `/nomad-cluster/acl` | SSM path prefix for ACL tokens |

Edit `terraform.tfvars` to override defaults.

## Scaling Clients

**Via Terraform** (persistent):
```bash
# Edit terraform.tfvars: client_count = 3
terraform apply
```

**Via autoscaler** (automatic):
The Nomad Autoscaler monitors cluster CPU/memory allocation and scales the client ASG when usage exceeds 70%.

## Scaling Policies Workflow

1. Add or edit one or more policy files in `scaling-policies/`.
2. Run `terraform apply` to upload the updated policy zip to S3.
3. Run `./scripts/deploy-autoscaler.sh ...` to restart the autoscaler and load the updated policies.

## Nomad UI

1. Start SSM port forward (see step 4 above)
2. Open `http://localhost:4646/ui`
3. Paste your token Secret ID in the auth dialog

## Security

- **No SSH ports open** — access via AWS SSM Session Manager only
- **IMDSv2 enforced** — instance metadata requires session tokens
- **EBS encrypted** — all volumes use gp3 with encryption
- **ACL enabled** — three scoped tokens (management, operator, autoscaler)
- **Least-privilege IAM** — separate roles per component
- **Security groups** — Nomad ports restricted to VPC CIDR only
- **Spot instances** — clients use mixed instance policy (capacity-optimized)
- **Tokens in SSM** — SecureString parameters, not in code or state
- **HashiCorp base AMI** — `hc-base-ubuntu-2404` with EDR enabled

## SSM Token Parameters

| Parameter | Purpose |
|-----------|---------|
| `/nomad-cluster/acl/management-token` | Full admin access (use sparingly) |
| `/nomad-cluster/acl/operator-token` | Day-to-day job management |
| `/nomad-cluster/acl/autoscaler-token` | Autoscaler read + scale permissions |

## Destroying

```bash
terraform destroy
cd state/ && terraform destroy  # removes state bucket + lock table
```
