# STV project

## AMI

The Amazon Machine Image (AMI) subfolder defines the default OS and software


## EC2 configuration

EC2 instance with DART Installed

NOTE: elastic IP (eip) and Data volume (ebs) created separately since we don't want to destroy them if remaping to a different EC2 instance type or other changes. so first:

```
cd ebs
terraform init
terraform apply
```

```
cd eip
terraform init 
terraform apply
```

```
cd ec2
terraform init
terraform workspace new dart
terraform apply
```

Successfully instance creation will look like something like this:
```
Apply complete! Resources: 0 added, 2 changed, 0 destroyed.

Outputs:

instance_id = "i-0f0564ea764f00847"
instance_public_ip = "35.88.128.224"
```


! Instance will be automatically stopped if CPU utilization <=2% for an hour !

Restart the stopped instance with:
```
aws ec2 start-instances --instance-ids INSTANCEID --region us-west-2
```

### NOTE: it can take a few minutes to restart the instance

