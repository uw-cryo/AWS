# IAM configuration for tacolab AWS account

Configure permissions for account users (this requires `admin` permissions in the AWS account)

This configuration attempts to follow [IAM security best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_securely-create-iam-users):

* new users *only* have permissions to change their own password and keys
* users (including admins), must assume a time-limited role to create and modify resources
* a permissions boundary is set for all roles (except admin) to limit to specific AWS services and regions

For simplicity, there are 5 roles in the account:

For administration:
* admin (can do anything)
* poweruser (can do anything w/n permissions boundary except IAM things)
* readonly (can only see what exists w/n permissions boundary)
------
For everyone:
* tacowrite (full permissions for ec2 and s3)
* tacoread (can only read ec2 and s3)


```
# Modify terraform.tfvars to add users
conda activate tacoAWS
terraform init
terraform apply
```

### Console usage

The first time you sign in to https://tacolab.signin.aws.amazon.com/console, set up [Multi Factor Authentication](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_enable_virtual.html#enable-virt-mfa-for-iam-user). The [Google Authenticator App](https://support.google.com/accounts/answer/1066447) works well.

For future sign-ins, go straight to using a specific role (readonly, or poweruser):
https://signin.aws.amazon.com/switchrole?roleName=poweruser&account=tacolab  

### CLI usage

This is a bit tedious, but the commands only need to be run once per day, and will prevent accidental resource creation.

Note that you need to authenticate with MFA, then assume a role which has time-limited permissions. Note below `--token-code` comes from your MFA App and changes every 30 seconds [AWS documentation](https://aws.amazon.com/premiumsupport/knowledge-center/authenticate-mfa-cli/):

On your personal laptop, you should have a `~/.aws/credentials` file that looks like:
```
[default]
aws_access_key_id=AKIAXXXXXXXXXXXXXXX
aws_secret_access_key=rFxXXXXXXXXXXXXXXXXXXXXXX
```

In a terminal `aws sts get-caller-identity` will return something like:
```
{
    "UserId": "XXXXXXXXXXXXX",
    "Account": "118211588532",
    "Arn": "arn:aws:iam::118211588532:user/quinn"
}
```

By default, you do not have permissions to do things (`aws s3 ls` will result in `An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied`)

This following command returns credentials good for 12 hours
`aws sts get-session-token --serial-number arn:aws:iam::118211588532:mfa/quinn --token-code 7313871`

Use those credentials in for subsequent commands:
```
export AWS_ACCESS_KEY_ID=ASIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_SESSION_TOKEN=AQoDYXdzEJr...<remainder of session token>
```

Once authenticated, you can assume different roles. For example, the `poweruser` role allows you to launch instances and create buckets. For `--role-session-name` use your username and the date
`aws sts assume-role --role-arn "arn:aws:iam::118211588532:role/poweruser" --role-session-name quin20220428`

Again, export the temporary credentials output by the command, which by default are good for 12 hours
```
export AWS_ACCESS_KEY_ID=ASIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_SESSION_TOKEN=AQoDYXdzEJr...<remainder of session token>
```

`aws sts get-caller-identity` will show:
```
{
    "UserId": "AROARXBPVWG2DL3E2YEBP:quin20220428",
    "Account": "118211588532",
    "Arn": "arn:aws:sts::118211588532:assumed-role/poweruser/quin20220428"
}
```

Confirm that you have permissions to see things - `aws s3 ls` should show something like:
```
2019-03-13 22:27:17 evwhs-dg
2022-02-22 20:08:16 gda2022
```

After 12 hours if you try to use these credentials you'll be denied access and have to repeat the process
`An error occurred (ExpiredToken) when calling the GetCallerIdentity operation: The security token included in the request is expired`

To go back to your original credentials `unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN`

If for some reason you accidentally expose the `poweruser` credentials, you can [revoke active sessions](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_revoke-sessions.html):

## Resources

* https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest
* https://stackoverflow.com/questions/40631977/how-do-i-use-terraform-to-maintain-manage-iam-users
* https://learn.hashicorp.com/tutorials/terraform/for-each
* https://learn.hashicorp.com/tutorials/terraform/aws-assumerole


## Misc notes:

Can't use convenient aws profile with MFA for terraform config
https://stackoverflow.com/questions/52432717/terraform-unable-to-assume-roles-with-mfa-enabled
