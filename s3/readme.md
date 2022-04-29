# Create an object storage bucket

For example, we'll create a bucket called s3://quinnsar in us-east-2 to use with [AWS Sagemaker Studio Lab](https://aws.amazon.com/sagemaker/studio-lab/)

1. Activate the terraform environment and ensure you're using an AWS role with write permissions:
```
conda activate tacoAWS
source set_temporary_credentials.sh tacowrite 123456
```

2. Create a bucket
```
terraform workspace new quinn
terraform init
terraform apply -var-file="terraform.tfvars"
```

3. Write contents to the bucket:
https://docs.aws.amazon.com/cli/latest/reference/s3/
```
aws s3 cp dem.tif s3://quinnsar/dems/dem.tif
```

4. Configure temporary credentials on another machine (SageMaker Studio Lab):

Note if you only need to read from the bucket, consider the readonly role

The following command exports current credentials to copy and paste elsewhere: `printf "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID\nexport AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY\nexport AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN\n"`)
```
export AWS_ACCESS_KEY_ID=ASIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_SESSION_TOKEN=AQoDYXdzEJr...<remainder of session token>
```

5. Copy bucket contents to local drive
```
aws s3 cp s3://quinnsar/dems/dem.tif .
```

6. Delete and remove the bucket

If you don't need to keep the bucket around, first empty it, then destroy with terraform:
```
aws s3 rm --recursive s3://quinnsar
terraform destroy --var-file="terraform.tfvars"
```
