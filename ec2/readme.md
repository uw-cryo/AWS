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

1. Connect via ssh:
```
ssh -i "~/.ssh/id_rsa.pub" <PUBLIC IP>
```

1. Delete it

If you don't need to keep the bucket around, first empty it, then destroy with terraform:
```
terraform destroy --var-file="terraform.tfvars"
terraform workspace select default
terraform workspace delete eric-micro
```
