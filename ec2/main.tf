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

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    #values = ["*ubuntu-focal-20.04-amd64-server-*"]
    values = ["*ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical

}


data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "allow-ssh" {
  name        = "allow-ssh"
  description = "Allow SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # Only allow ingress from UW IPs
    # https://s3.amazonaws.com/tr-learncanvas/docs/IP_Filtering_in_Canvas.pdf
    # Or specific IP: 205.175.118.122/32
    cidr_blocks = ["205.175.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_key_pair" "ssh-key" {
  key_name   = var.ssh-key-name
  public_key = var.ssh-public-key

  tags = local.tags
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = terraform.workspace

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance
  availability_zone           = local.availability_zone
  associate_public_ip_address = true
  key_name                    = var.ssh-key-name
  vpc_security_group_ids      = [aws_security_group.allow-ssh.id]

  tags = local.tags
}

# NOTE: default disk is 8GB and cant resize...
resource "aws_ebs_volume" "this" {
  availability_zone = local.availability_zone
  size              = var.disk_size

  tags = local.tags
}

resource "aws_volume_attachment" "this" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.this.id
  instance_id = module.ec2_instance.id
}
