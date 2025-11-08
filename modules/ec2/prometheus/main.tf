resource "aws_instance" "prometheus" {
    ami = var.ec2_prometheus_ami
    instance_type = var.ec2_prometheus_instance_type
    tags = {
      Name = var.ec2_prometheus_name
    }
    user_data = templatefile("../../scripts/prometheus.sh",{
      s3_bucket_name = var.s3_bucket_name
      Node_Exp_Version = var.Node_Exp_Version
      Prometheus_Version = var.Prometheus_Version
    })
    key_name = "cloudpulse"
}