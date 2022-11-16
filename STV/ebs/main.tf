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


# NOTE: secondary disk for data storage
resource "aws_ebs_volume" "dart-data" {
  availability_zone = local.availability_zone
  size              = var.disk_size

  lifecycle {
    prevent_destroy = true
  }

  tags = "${merge(local.tags, {Name="stv-dart-data"})}"

}