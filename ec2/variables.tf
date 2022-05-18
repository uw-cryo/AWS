variable "instance" {
  description = "Type of AWS instance"
  type        = string
  default     = "t2.micro"
}

variable "region" {
  description = "AWS region to deploy instance"
  type        = string
  default     = "us-west-2"
}

variable "ssh-key-name" {
  description = "Name for SSH key (e.g. scottskey)"
  type        = string
}

variable "ssh-public-key" {
  description = "Public key to connect to EC2 instance via SSH"
  type        = string
}

variable "disk_size" {
  description = "EBS Volume disk size (GB)"
  type        = number
  default     = 50
}
