# A deliberately hardened S3 bucket — the IaC scanners (Trivy config / Checkov)
# should find no HIGH/CRITICAL misconfigurations here. Removing any of the
# hardening blocks below is how you demonstrate the gate catching a regression.

terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  type    = string
  default = "devsecops-demo-artifacts"
}

resource "aws_kms_key" "artifacts" {
  description             = "Customer-managed key for the artifacts bucket"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "artifacts" {
  bucket = var.bucket_name
  tags = {
    Project = "devsecops-cicd"
  }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.artifacts.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
