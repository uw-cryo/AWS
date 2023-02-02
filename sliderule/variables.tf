variable "bucket_name" {
  description = "Name of bucket"
  type        = string
  default     = "alpastor_taco"
}

variable "region" {
  description = "AWS region of bucket"
  type        = string
  default     = "us-west-2"
}
