#!/bin/bash
set -euo pipefail

# Install SSM agent (apt method for Ubuntu 24.04 without snap)
if command -v snap >/dev/null 2>&1; then
  snap install amazon-ssm-agent --classic || true
  systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || true
  systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service || true
else
  mkdir -p /tmp/ssm && cd /tmp/ssm
  curl -fsSL "https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_$(dpkg --print-architecture)/amazon-ssm-agent.deb" -o amazon-ssm-agent.deb
  dpkg -i amazon-ssm-agent.deb || true
  systemctl enable amazon-ssm-agent || true
  systemctl start amazon-ssm-agent || true
  cd /
fi

# Install Nomad + Docker
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list

apt-get update && apt-get install -y nomad consul docker-ce docker-ce-cli containerd.io jq

# Get instance metadata (IMDSv2)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

# Configure Nomad client
cat > /etc/nomad.d/nomad.hcl <<EOF
datacenter = "dc1"
region     = "${region}"
data_dir   = "/opt/nomad/data"

bind_addr = "0.0.0.0"

advertise {
  http = "$PRIVATE_IP:4646"
  rpc  = "$PRIVATE_IP:4647"
  serf = "$PRIVATE_IP:4648"
}

client {
  enabled    = true
  node_class = "${node_class}"

  server_join {
    retry_join = ["provider=aws tag_key=NomadRole tag_value=server region=${region}"]
  }
}

acl {
  enabled = true
}

consul {
  address = "127.0.0.1:8500"
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

plugin "docker" {
  config {
    allow_privileged = false
  }
}

telemetry {
  prometheus_metrics = true
}
EOF

systemctl enable docker nomad
systemctl start docker nomad

# Configure Consul client
cat > /etc/consul.d/consul.hcl <<CONSUL
datacenter = "dc1"
data_dir   = "/opt/consul/data"
bind_addr  = "$PRIVATE_IP"

server = false

retry_join = ["provider=aws tag_key=NomadRole tag_value=server region=${region}"]

client_addr = "0.0.0.0"
CONSUL

systemctl enable consul
systemctl start consul
