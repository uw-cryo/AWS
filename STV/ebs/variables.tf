variable "region" {
  description = "AWS region to deploy instance"
  type        = string
  default     = "us-west-2"
}

variable "disk_size" {
  description = "EBS Volume disk size (GB)"
  type        = number
  default     = 50
}
