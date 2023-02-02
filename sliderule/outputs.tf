output "s3_bucket_arn" {
  value       = module.s3_bucket_sliderule.s3_bucket_arn
  description = "The ARN of the S3 bucket"
}
