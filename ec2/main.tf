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

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
        name   = "virtualization-type"
        values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical

}

resource "aws_key_pair" "ssh-key" {
  key_name   = "ssh-key"
  public_key = var.ssh-public-key
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "${terraform.workspace}"

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance
  associate_public_ip_address = true
  key_name         = "ssh-key"

  tags = {
    Owner = reverse(split(":", data.aws_caller_identity.current.arn))[0]
  }
}
