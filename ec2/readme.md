# Create an ec2 instance

1. Activate the terraform environment and ensure you're using an AWS role with write permissions:
```
conda activate tacoAWS
source set_temporary_credentials.sh tacowrite 123456
```

1. Create a virtual machine
Note, this can take several minutes... the instance will have the same name as your workspace (e.g. eric-micro)
```
terraform init
terraform workspace new eric-micro
terraform apply -var-file="terraform.tfvars"
```

1. Enter public SSH Key
https://git-scm.com/book/it/v2/Git-on-the-Server-Generating-Your-SSH-Public-Key

1. Connect via ssh (pass *private* key and use public IP output by terraform)
```
ssh -i ~/.ssh/id_rsa ubuntu@35.89.127.177
```

1. Temporarily stop and restart instance (instance ID output by terraform)
```
aws ec2 stop-instances --instance-ids i-01dbfdeb77a94eee3
aws ec2 start-instances --instance-ids i-01dbfdeb77a94eee3
```

1. Completely delete it (and all attached drives)

If you don't need to keep the bucket around, first empty it, then destroy with terraform:
```
terraform destroy --var-file="terraform.tfvars"
terraform workspace select default
terraform workspace delete eric-micro
```
