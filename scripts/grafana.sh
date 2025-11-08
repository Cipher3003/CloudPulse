#!/bin/bash
set -eux

# 1. Install dependencies (wget)
if command -v yum &>/dev/null; then
  yum install -y wget
elif command -v apt-get &>/dev/null; then
  apt-get update && apt-get install -y wget
fi

# 2. Set Grafana version
G_VER="11.2.2"

# 3. Download & extract Grafana
mkdir -p /opt/grafana
cd /opt/grafana
wget https://dl.grafana.com/oss/release/grafana-${G_VER}.linux-amd64.tar.gz
tar -xzf grafana-${G_VER}.linux-amd64.tar.gz --strip-components=1
rm grafana-${G_VER}.linux-amd64.tar.gz

# 4. Create grafana user if not exists
id -u grafana &>/dev/null || useradd --no-create-home --shell /bin/false grafana

# 5. Set permissions
chown -R grafana:grafana /opt/grafana

# 6. Create systemd service
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

# 7. Wait for Grafana to start
sleep 10

# 8. Get private IP of instance
PROM_IP=\$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# 9. Create Prometheus datasource JSON
cat > /tmp/datasource.json <<EOF
{
  "name": "Prometheus",
  "type": "prometheus",
  "access": "proxy",
  "url": "http://\${PROM_IP}:9090",
  "basicAuth": false,
  "isDefault": true
}
EOF

# 10. Send datasource to Grafana API
for i in {1..10}; do
  if curl -s -X POST -H "Content-Type: application/json" \
    -d @/tmp/datasource.json \
    http://admin:admin@localhost:3000/api/datasources; then
    echo "Datasource created"
    break
  fi
  echo "Waiting for Grafana to be ready..."
  sleep 5
done

echo "✅ Grafana installed and Prometheus datasource added (admin/admin)."
