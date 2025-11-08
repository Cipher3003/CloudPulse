#!/bin/bash
set -eux

# Install dependencies
if command -v yum &>/dev/null; then
  yum install -y wget awscli jq
elif command -v apt-get &>/dev/null; then
  apt-get update && apt-get install -y wget awscli jq
fi

# Download & setup Grafana
mkdir -p /opt/grafana
cd /opt/grafana
wget https://dl.grafana.com/oss/release/grafana-${Grafana_Version}.linux-amd64.tar.gz
tar -xzf grafana-${Grafana_Version}.linux-amd64.tar.gz --strip-components=1
rm grafana-${Grafana_Version}.linux-amd64.tar.gz

# Create grafana user
id -u grafana &>/dev/null || useradd --no-create-home --shell /bin/false grafana
chown -R grafana:grafana /opt/grafana

# Systemd service
cat > /etc/systemd/system/grafana.service <<EOF
[Unit]
Description=Grafana
After=network.target

[Service]
Type=simple
User=grafana
Group=grafana
WorkingDirectory=/opt/grafana
ExecStart=/opt/grafana/bin/grafana-server --homepath=/opt/grafana
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now grafana

# Wait for Grafana
sleep 15

# Create Grafana datasource JSON
cat > /tmp/datasource.json <<EOF
{
  "name": "Prometheus",
  "type": "Prometheus",
  "access": "proxy",
  "url": "http://${prometheus_ip}:9090",
  "basicAuth": false,
  "isDefault": true
}
EOF

# Add datasource via API
for i in {1..10}; do
  if curl -s -X POST -H "Content-Type: application/json" \
    -d @/tmp/datasource.json \
    http://admin:admin@localhost:3000/api/datasources; then
    echo "✅ Datasource created successfully."
    break
  fi
  echo "Waiting for Grafana to be ready..."
  sleep 5
done

echo "✅ Grafana installed and dynamically connected to Prometheus."
