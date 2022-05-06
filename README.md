# Infrastructure-as-code on AWS

This repository contains [Terraform](https://www.terraform.io) code, to easily
create and remove Cloud resources on AWS for the tacoLab.

| subfolder | description |
| - | - |
| [s3_bucket](s3_bucket) | Private object storage |
| [basic_virtual_machine](basic_virtual_machine) | Virtual machine with Ubuntu 20.04 |

## Setup

We'll use [conda-lock](https://github.com/conda-incubator/conda-lock) to create an
environment that includes command line utilities to execute code in this repository.
In particular, we need `terraform` and the [AWS Command Line Interface (CLI)](https://aws.amazon.com/cli/)

```
git clone https://github.com/uw-cryo/AWS.git
cd AWS
conda-lock install -p ${CONDA_PREFIX}/envs/tacoAWS
conda activate tacoAWS
```
NOTE: Change the prefix to wherever you have your conda environments installed. If you don't already have `conda-lock`, install it with `conda create -n condalock conda-lock mamba -c conda-forge`

NOTE: if packages aren't available from conda-forge, you can install binaries of [Terraform](https://www.terraform.io/downloads) [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### AWS credentials

Each lab member has an IAM User configured in [./users](./users). For instructions on setting up Multi-Factor-Authentication and other detailes see the [users readme file](./users/readme.md#Console-usage)

You must assume a role to have credentials to create, modify, or destroy cloud resources. We have a helper script to do this (`./set_temporary_credentials.sh`):

To assume read-only permissions:
```
source set_temporary_credentials.sh tacoread
```

To assume read-write permissions where `123456` is your MFA code:
```
source set_temporary_credentials.sh tacowrite 123456
```

## Organization

Each subfolder contains a stand-alone logical group of Cloud resources. To create the infrastructure,
navigate to a subfolder in the terminal and follow the README.md instructions.

### Workspaces
Each subfolder contains a recipe for a group of cloud resources with a self-describing subfolder name (`ec2`). Let's say several lab members each need a virtual machine. The recipe is the same but each time we use it, we create a new [Terraform Workspace](https://www.terraform.io/language/state/workspaces) to keep track of the Cloud resources created and not interfere with one another. For example:

```
cd ec2

# Connect to state backend (see 'Initial Setup' section below)
terraform init

terraform workspace new scotts-projectx

# Optionally edit terraform.tfvars to change things like region or machine type
terraform apply

# Easily remove any costly Cloud resources
terraform destroy
terraform workspace delete scott-incubator2022
```

#### Active workspaces
⚠️ Everyone with sufficient AWS privileges can see, modify, and delete terraform-managed resources:
```
terraform workspace list
terraform workspace select scotts-projectx
terraform state list
```


## Initial Setup

NOTE: this only needs doing once!

Terraform keeps track of Cloud resources in "state" files, which are stored in an AWS "S3 bucket"). We've documented this setup in the [backend folder](./backend)

NOTE: `.tfstate` files are created separately for each collection of infrastructure,
under the [BUCKET]/[KEY], for example for our basic_virtual_machine
the configuration is tracked in `s3://tacolab-tfstate/linux-vm.tfstate`


## References

* https://learn.hashicorp.com/collections/terraform/aws-get-started
* https://www.terraform.io/docs/providers/aws
* https://github.com/terraform-providers/terraform-provider-aws/tree/master/examples
* https://github.com/terraform-aws-modules
