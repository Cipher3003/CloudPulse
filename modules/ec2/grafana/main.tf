resource "aws_instance" "grafana" {
    ami = var.ec2_grafana_ami
    instance_type = var.ec2_grafana_instance_type
    tags = {
      Name = var.ec2_grafana_name
    }
    user_data = file("../../scripts/grafana.sh")

    key_name = "cloudpulse"
}