name        = "platform-prod"
environment = "prod"

vpc_cidr        = "10.30.0.0/16"
azs             = ["us-east-1a", "us-east-1b"]
private_subnets = ["10.30.1.0/24", "10.30.2.0/24"]
public_subnets  = ["10.30.101.0/24", "10.30.102.0/24"]

app_instance_count   = 2
app_instance_type    = "t3.small"
db_instance_class    = "db.t3.small"
db_allocated_storage = 50
