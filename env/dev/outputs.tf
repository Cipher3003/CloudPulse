output "prometheus_public_ip" {
  value = module.ec2_prometheus.prometheus_public_ip
}

output "grafana_public_ip" {
  value = module.ec2_grafana.grafana_public_ip
}
