terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # backend "s3" {
  #   bucket = "<S3_BUCKET>"
  #   key    = "tfstates/canoe"
  #   region = "us-east-1"
  #   dynamodb_table = "<DYNAMO_TABLE>"
  # }
}

provider "aws" {
  region = "us-east-1"
  profile = "personal"
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
