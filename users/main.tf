provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      Project   = "TacoLab"
      Terraform = "true"
    }
  }
}

# Allows for https://tacolab.signin.aws.amazon.com/console
module "iam_account" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-account"
  version = "~> 4"

  account_alias = "tacolab"

  minimum_password_length = 20
  require_numbers         = false
}

# Existing users not managed via terraform
data "aws_iam_user" "dshean" {
  user_name = "dshean"
}
data "aws_iam_user" "scottyh" {
  user_name = "scottyh"
}
locals {
  admin_users = ["dshean", "scottyh"]
  admin_arns  = [data.aws_iam_user.dshean.arn, data.aws_iam_user.scottyh.arn]
}

# Limit everyone to specific services and regions
# us-east-1 required for AWS Console
# us-west-2 where NASA data lives
# us-east-2 where SageMaker StudioLab is hosted
module "iam_policy_boundary" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4"

  name        = "MaxPermissions"
  path        = "/"
  description = "Restrict to certain services and regions"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*",
          "ec2:*",
          "iam:*"
        ]
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:RequestedRegion" : [
              "us-west-2",
              "us-east-1",
              "us-east-2"
            ]
          }
        }
      }
    ]
  })
}

# Custom lab read-write policy
module "iam_policy_write" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4"

  name        = "tacolab-write"
  path        = "/"
  description = "Tacolab full permissions for specific AWS services"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*",
          "ec2:*",
        ]
        "Resource" : "*",
      }
    ]
  })
}

# S3 read-only policy
module "iam_read_only_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-read-only-policy"
  version = "~> 4"

  name        = "tacolab-readonly"
  path        = "/"
  description = "Tacolab read-only"

  allowed_services = ["s3"]
}

# Create Account IAM users
module "iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 4"

  for_each = var.user
  name     = each.key

  permissions_boundary          = module.iam_policy_boundary.arn
  create_iam_user_login_profile = true
  create_iam_access_key         = false
  password_reset_required       = false
  force_destroy                 = true
}


# Basic self-management permission for tacolab group
module "iam_group_with_policies" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "~> 4"

  name                              = "tacolab"
  group_users                       = var.user
  attach_iam_self_management_policy = true
}

module "iam_assumable_role_read" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 4"

  trusted_role_arns = concat(local.admin_arns, [for user in var.user : module.iam_user["${user}"].iam_user_arn])
  create_role = true
  role_name         = "tacoread"
  role_requires_mfa = false

  custom_role_policy_arns = [
    module.iam_read_only_policy.arn
  ]
}

module "iam_assumable_role_write" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 4"

  trusted_role_arns = concat(local.admin_arns, [for user in var.user : module.iam_user["${user}"].iam_user_arn])
  create_role = true
  role_name         = "tacowrite"
  role_requires_mfa = true

  custom_role_policy_arns = [
    module.iam_policy_write.arn
  ]
}

# ADMINISTRATORS AND POWERUSERS
# ---------
# https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_job-functions.html
module "iam_assumable_role_admin" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-roles"
  version = "~> 4"

  trusted_role_arns       = local.admin_arns
  max_session_duration    = 43200
  create_admin_role       = true
  admin_role_requires_mfa = true
}

# careful with 'readonly'! https://posts.specterops.io/aws-readonlyaccess-not-even-once-ffbceb9fc908
module "iam_assumable_roles_poweruser" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-roles"
  version = "~> 4"

  trusted_role_arns                       = concat(local.admin_arns, [for user in var.poweruser : module.iam_user["${user}"].iam_user_arn])
  max_session_duration                    = 43200
  create_poweruser_role                   = true
  poweruser_role_requires_mfa             = true
  poweruser_role_permissions_boundary_arn = module.iam_policy_boundary.arn

  create_readonly_role       = true
  readonly_role_requires_mfa = true
}

# Add select members to 'poweruser' group that can assume 'poweruser' role
# User *must* have logged in with MFA to switch to admin or poweruser roles
module "iam_group_with_assumable_roles_policy_poweruser" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-assumable-roles-policy"
  version = "~> 4"

  name = "poweruser"

  assumable_roles = [
    module.iam_assumable_roles_poweruser.poweruser_iam_role_arn,
    module.iam_assumable_roles_poweruser.readonly_iam_role_arn
  ]

  group_users = var.poweruser
}

module "iam_group_with_assumable_roles_policy_admin" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-assumable-roles-policy"
  version = "~> 4"

  name = "admin"

  assumable_roles = [
    module.iam_assumable_role_admin.admin_iam_role_arn,
    module.iam_assumable_roles_poweruser.poweruser_iam_role_arn,
    module.iam_assumable_roles_poweruser.readonly_iam_role_arn
  ]

  group_users = local.admin_users
}
