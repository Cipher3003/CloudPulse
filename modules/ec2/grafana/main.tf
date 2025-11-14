resource "aws_instance" "grafana" {
    ami = var.ec2_grafana_ami
    instance_type = var.ec2_grafana_instance_type
    tags = {
      Name = var.ec2_grafana_name
    }
    user_data = templatefile("../../scripts/grafana.sh",{
      prometheus_ip= var.prometheus_private_ip
      Grafana_Version = var.Grafana_Version
    })

    key_name = "cloudpulse"
}