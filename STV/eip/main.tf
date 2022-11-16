provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project   = "TacoLab"
      Terraform = "true"
    }
  }
}

locals {
  # a,b,or c for AZ
  availability_zone = format("%sa", var.region)
  tags              = { Owner = reverse(split(":", data.aws_caller_identity.current.arn))[0] }
}

data "aws_caller_identity" "current" {}


# Associate a static IP so it doesn't change on reboot
resource "aws_eip" "eip_manager" {
  lifecycle {
    prevent_destroy = true
  }

  tags = "${merge(local.tags, {Name="stv-dart"})}"
}