output "prometheus_public_ip" {
  value = aws_instance.prometheus.public_ip
}

output "prometheus_private_ip" {
  value = aws_instance.prometheus.private_ip
}