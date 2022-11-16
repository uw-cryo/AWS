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


data "aws_vpc" "default" {
  default = true
}

data "aws_eip" "stv_dart" {
  tags = {
    Name = "stv-dart"
  }
}

data "aws_ami" "stv_dart" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["stv-dart"]
  }
}

data "aws_ebs_volume" "stv_dart" {
  filter {
    name   = "tag:Name"
    values = ["stv-dart-data"]
  }
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
    # cidr_blocks = ["205.175.0.0/16"]
    # cidr_blocks = ["97.126.8.33/32"]
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# AMI from packer (stv-ec2 subfolder)
# NOTE: must specify correct AMI or else
#  Error: error collecting instance settings: empty result
module "ec2_instance" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 4.0"
  name                   = "stv-dart"
  ami                    = data.aws_ami.stv_dart.id
  instance_type          = var.instance
  availability_zone      = local.availability_zone
  enable_volume_tags     = false
  key_name               = "stv-dart"
  vpc_security_group_ids = [aws_security_group.allow-ssh.id]
  user_data              = <<EOT
#!/bin/bash
echo 'Mounting Data Volume...'
# Wait for extra EBS mount before formatting and mounting!
# while [ -e /dev/nvme1n1 ] ; do sleep 1 ; done
sleep 30
lsblk --output NAME,TYPE,SIZE,FSTYPE,MOUNTPOINT,LABEL
mkfs -t ext4 /dev/nvme1n1
mkdir /data
mount /dev/nvme1n1 /data
chown -R ubuntu:ubuntu /data

echo 'Configuring Default Environment...'
echo export "conda activate base" >> /etc/profile
echo export PATH="$PATH:/opt/StereoPipeline/bin:/opt/dart/bin" >> /etc/profile
EOT

  root_block_device = [{
    volume_size = 20
  }]

  tags = local.tags
}

# Associate a static IP (eip) so it doesn't change on reboot
resource "aws_eip_association" "eip_assoc" {
  instance_id   = module.ec2_instance.id
  allocation_id = data.aws_eip.stv_dart.id
}


# Automatically stop instance if CPU<2% for all 24 checks in 1 day 
# (samples every 1 hr instead of default period = 5 min)
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "cpu-utilization"
  comparison_operator = "LessThanOrEqualToThreshold"
  datapoints_to_alarm = "24"
  evaluation_periods  = "24"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "3600" #seconds
  statistic           = "Maximum"
  threshold           = "2"
  unit                = "Percent"
  alarm_description   = "Monitor EC2 low CPU utilization"
  alarm_actions = [
    "arn:aws:automate:${var.region}:ec2:stop"
  ]
  insufficient_data_actions = []
  dimensions = {
    InstanceId = module.ec2_instance.id
  }

  tags = local.tags
}

# Attach external drive for data storage
resource "aws_volume_attachment" "dart-data" {
  device_name  = "/dev/sdh"
  volume_id    = data.aws_ebs_volume.stv_dart.id
  instance_id  = module.ec2_instance.id
  skip_destroy = true
}
