terraform {
  required_version = "~> 1.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket  = "tacolab-tfstate"
    key     = "dart-eip.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
