locals {
  tags = {
    Project     = "aws-platform"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ----------------------------------------------------------------------------
# Network
# ----------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${var.name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = local.tags
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ----------------------------------------------------------------------------
# Security groups
# ----------------------------------------------------------------------------
resource "aws_security_group" "app" {
  name_prefix = "${var.name}-app-"
  description = "App instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from within the VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "HTTP from within the VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group" "db" {
  name_prefix = "${var.name}-db-"
  description = "RDS access from the app tier only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Postgres from the app security group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# ----------------------------------------------------------------------------
# App fleet (Ansible configures these instances)
# ----------------------------------------------------------------------------
module "app" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7"
  count   = var.app_instance_count

  name                   = "${var.name}-app-${count.index}"
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.app_instance_type
  subnet_id              = element(module.vpc.private_subnets, count.index)
  vpc_security_group_ids = [aws_security_group.app.id]

  # Hardening: require IMDSv2 and encrypt the root volume.
  metadata_options = {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device = [{
    encrypted = true
  }]

  # Role tag drives the Ansible aws_ec2 dynamic-inventory grouping.
  tags = merge(local.tags, { Role = "app" })
}

# ----------------------------------------------------------------------------
# Managed Postgres
# ----------------------------------------------------------------------------
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.10"

  identifier = "${var.name}-db"

  engine               = "postgres"
  engine_version       = "16"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage

  db_name                     = "appdb"
  username                    = "appadmin"
  manage_master_user_password = true
  port                        = 5432

  multi_az               = var.environment == "prod"
  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.db.id]

  storage_encrypted   = true
  deletion_protection = false
  skip_final_snapshot = true

  tags = local.tags
}
