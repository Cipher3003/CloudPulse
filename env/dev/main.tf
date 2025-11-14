module "ec2_grafana" {
    source = "../../modules/ec2/grafana"
    ec2_grafana_name = var.ec2_grafana_name
    ec2_grafana_ami = var.ec2_grafana_ami
    ec2_grafana_instance_type = var.ec2_grafana_instance_type
    prometheus_private_ip = module.ec2_prometheus.prometheus_private_ip
    Grafana_Version = var.Grafana_Version
    depends_on = [ module.ec2_prometheus ]
}

module "ec2_prometheus" {
    source = "../../modules/ec2/prometheus"
    ec2_prometheus_name = var.ec2_prometheus_name
    ec2_prometheus_ami = var.ec2_prometheus_ami
    ec2_prometheus_instance_type = var.ec2_prometheus_instance_type
    s3_bucket_name = var.s3_bucket_name
    Node_Exp_Version = var.Node_Exp_Version
    Prometheus_Version = var.Prometheus_Version
    depends_on = [ module.s3_logs ]
}

module "s3_logs" {
    source = "../../modules/s3"
    s3_bucket_name = var.s3_bucket_name
}

module "vpc_default" {
    source = "../../modules/vpc"
}

module "security_gp" {
    source = "../../modules/security_gp"
    vpc_id = module.vpc_default.vpc_id
}

module "iam" {
    source = "../../modules/iam"
    s3_bucket_name = var.s3_bucket_name
}