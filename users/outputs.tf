output "user_temporary_passwords" {
  description = "User console password for each iam user in the account"
  value       = { for u in var.user : u => nonsensitive(module.iam_user[u].iam_user_login_profile_password) }
}
