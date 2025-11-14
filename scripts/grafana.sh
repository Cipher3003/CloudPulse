#!/bin/bash
set -eux

# 1. Install dependencies
if command -v yum &>/dev/null; then
  yum install -y wget
elif command -v apt-get &>/dev/null; then
  apt-get update && apt-get install -y wget
fi

# Install Grafana
mkdir -p /opt/grafana
cd /opt/grafana
wget https://dl.grafana.com/oss/release/grafana-${Grafana_Version}.linux-amd64.tar.gz
tar -xzf grafana-${Grafana_Version}.linux-amd64.tar.gz --strip-components=1
rm grafana-${Grafana_Version}.linux-amd64.tar.gz

# Create user & permissions
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
systemctl enable grafana

# Provisioning configuration
mkdir -p /opt/grafana/conf/provisioning/datasources
cat > /opt/grafana/conf/provisioning/datasources/prometheus.yml <<EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://${prometheus_ip}:9090
    isDefault: true
EOF

# Start Grafana
systemctl start grafana

echo "Grafana installed and Prometheus datasource provisioned at http://${prometheus_ip}:9090"
