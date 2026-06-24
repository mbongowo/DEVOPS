# Remote, locked state — one key per environment. Fill in and uncomment, then
# `terraform init -migrate-state`. Commented so CI validation needs no AWS.
#
# terraform {
#   backend "s3" {
#     bucket         = "REPLACE-ME-tfstate"
#     key            = "aws-platform/dev/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "REPLACE-ME-tflock"
#     encrypt        = true
#   }
# }
