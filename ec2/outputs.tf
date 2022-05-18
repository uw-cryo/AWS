output "image_id" {
  value = data.aws_ami.ubuntu.id
}

output "instance_id" {
  value = module.ec2_instance.id
}

output "instance_public_ip" {
  value = module.ec2_instance.public_ip
}
