#!/bin/bash
set -eux

# Create prometheus and node_exporter users
useradd --no-create-home --shell /bin/false prometheus || true
useradd --no-create-home --shell /bin/false node_exporter || true

# Install Node Exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${Node_Exp_Version}/node_exporter-${Node_Exp_Version}.linux-amd64.tar.gz
tar xvf node_exporter-${Node_Exp_Version}.linux-amd64.tar.gz
mv node_exporter-${Node_Exp_Version}.linux-amd64 /opt/node_exporter
ln -s /opt/node_exporter/node_exporter /usr/local/bin/node_exporter

# Create systemd service for Node Exporter
cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now node_exporter

# Install Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v${Prometheus_Version}/prometheus-${Prometheus_Version}.linux-amd64.tar.gz
tar xvf prometheus-${Prometheus_Version}.linux-amd64.tar.gz
mv prometheus-${Prometheus_Version}.linux-amd64 /opt/prometheus
ln -s /opt/prometheus/prometheus /usr/local/bin/prometheus
ln -s /opt/prometheus/promtool /usr/local/bin/promtool

# Config & data directories
mkdir -p /etc/prometheus /var/lib/prometheus /var/log/prometheus
chown -R prometheus:prometheus /opt/prometheus /etc/prometheus /var/lib/prometheus /var/log/prometheus

# Prometheus config
cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Prometheus systemd service
cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --log.level=info \
  --web.listen-address=:9090 \
  --log.format=json \
  --web.console.libraries=/opt/prometheus/console_libraries \
  --web.console.templates=/opt/prometheus/consoles
Restart=on-failure
StandardOutput=append:/var/log/prometheus/prometheus.log
StandardError=append:/var/log/prometheus/prometheus.log

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now prometheus

# Install AWS CLI
if command -v yum &>/dev/null; then
  yum install -y awscli
elif command -v apt-get &>/dev/null; then
  apt-get update && apt-get install -y awscli
fi

# Store logs to S3 every 5 minutes
cat > /etc/cron.d/prometheus-s3-sync <<EOF
*/5 * * * * root aws s3 sync /var/log/prometheus s3://${s3_bucket_name}/prometheus-logs/ --region $(curl -s http://169.254.169.254/latest/meta-data/placement/region)
EOF

chmod 644 /etc/cron.d/prometheus-s3-sync
systemctl restart crond || systemctl restart cron

echo "Prometheus and Node Exporter installed and running successfully. Logs will sync to s3://${s3_bucket_name}/prometheus-logs/"
