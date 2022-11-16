output "instance_id" {
  value = module.ec2_instance.id
}

output "instance_public_ip" {
  value = data.aws_eip.stv_dart.public_ip
}
