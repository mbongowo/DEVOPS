locals {
  tags = {
    Project     = "three-tier-devsecops"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# ----------------------------------------------------------------------------
# Network — official AWS VPC module
# ----------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true # cost guard: one NAT GW for dev
  enable_dns_hostnames = true

  # Tags required by the AWS Load Balancer Controller / EKS.
  public_subnet_tags  = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }

  tags = local.tags
}

# ----------------------------------------------------------------------------
# EKS — official AWS EKS module
# ----------------------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
    }
  }

  tags = local.tags
}

# ----------------------------------------------------------------------------
# ECR — one immutable, scan-on-push repository per tier
# ----------------------------------------------------------------------------
resource "aws_ecr_repository" "app" {
  for_each = toset(var.ecr_repositories)

  name                 = "${var.cluster_name}/${each.value}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}
