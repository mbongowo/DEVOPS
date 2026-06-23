# Remote, locked state. Create the bucket + DynamoDB lock table first, then
# fill these in and run `terraform init -migrate-state`. Left commented so
# `terraform init -backend=false` (CI validation) needs no AWS account.
#
# terraform {
#   backend "s3" {
#     bucket         = "REPLACE-ME-tfstate"
#     key            = "three-tier-eks/dev/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "REPLACE-ME-tflock"
#     encrypt        = true
#   }
# }
