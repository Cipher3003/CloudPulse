resource "aws_instance" "prometheus" {
    ami = var.ec2_prometheus_ami
    instance_type = var.ec2_prometheus_instance_type
    tags = {
      Name = var.ec2_prometheus_name
    }
    user_data = file("../../scripts/prometheus.sh")
    key_name = "cloudpulse"
}