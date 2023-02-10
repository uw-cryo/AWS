provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project   = "TacoLab"
      Terraform = "true"
    }
  }
}

data "aws_caller_identity" "current" {}


module "s3_bucket_sliderule" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3"
  bucket  = var.bucket_name

  lifecycle_rule = [{
    id      = "scratch"
    enabled = true
    expiration = {
      days = 7
    }
  }]


  tags = {
    Owner = reverse(split(":", data.aws_caller_identity.current.arn))[0]
  }
}

module "iam_iam-assumable-role_sliderule-write" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version     = "~> 5"
  create_role = true
  # AWS Max is 12 hours
  max_session_duration = 43200
  role_requires_mfa    = false
  trusted_role_arns    = [data.aws_caller_identity.current.account_id]
  role_name            = "sliderule-write"
  custom_role_policy_arns = [
    module.iam_policy_write.arn
  ]

}

# Custom lab read-write policy
module "iam_policy_write" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4"

  name        = "sliderule-write"
  path        = "/"
  description = "Tacolab write permissions for s3://sliderule-tacolab"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      }
    ]
  })
}

module "iam_iam-assumable-role_sliderule-read" {
  source               = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version              = "~> 5"
  create_role          = true
  max_session_duration = 43200
  role_requires_mfa    = false
  trusted_role_arns    = [data.aws_caller_identity.current.account_id]
  role_name            = "sliderule-read"
  custom_role_policy_arns = [
    module.iam_policy_read.arn
  ]
}


module "iam_policy_read" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4"

  name        = "sliderule-read"
  path        = "/"
  description = "Tacolab read permissions for s3://sliderule-tacolab"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion"
        ],
        "Resource" : "arn:aws:s3:::${var.bucket_name}/*"
      }
    ]
  })
}

