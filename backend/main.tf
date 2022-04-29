terraform {
  required_version = "~> 1.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "tacolab-tfstate"
  force_destroy = true
  tags = {
    Owner           = split("/", data.aws_caller_identity.current.arn)[1]
  }
}
