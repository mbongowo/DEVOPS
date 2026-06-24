name        = "platform-dev"
environment = "dev"

vpc_cidr        = "10.20.0.0/16"
azs             = ["us-east-1a", "us-east-1b"]
private_subnets = ["10.20.1.0/24", "10.20.2.0/24"]
public_subnets  = ["10.20.101.0/24", "10.20.102.0/24"]

app_instance_count = 1
app_instance_type  = "t3.micro"
db_instance_class  = "db.t3.micro"
