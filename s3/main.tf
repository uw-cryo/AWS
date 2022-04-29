provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project = "TacoLab"
      Terraform = "true"
    }
  }
}

data "aws_caller_identity" "current" {}

# Tag is 'user/scotty' or 'assumed-role/poweruser/scottyh'
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3"
  bucket = var.bucket_name
  tags = {
    Owner = reverse(split(":", data.aws_caller_identity.current.arn))[0]
  }
}
