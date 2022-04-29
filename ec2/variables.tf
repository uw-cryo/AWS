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

variable "ssh-public-key" {
  description = "Public key to connect to EC2 instance via SSH"
  type        = string
  default     = ""
}
