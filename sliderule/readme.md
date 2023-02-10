# Create SlideRule S3 Bucket

temporary storage space for LARGE sliderule geoparquet outputs

- *automatically wipe every week*
- create temporary roles that can be assumed:
    1. sliderule-read
    2. sliderule-write


```
terraform init
terraform workspace new sliderule
terraform plan
terraform apply
```

This shouldn't cost anything unless you're putting a lot of data in the bucket and egressing it (best to run analysis in aws us-west-2), if you want to remove it completely:
```
terraform destroy
```

# Usage

```
aws sts assume-role --role-arn arn:aws:iam::118211588532:role/sliderule-write --duration-seconds 43200  --role-session-name sliderule-write-scott > /tmp/tmpcreds.txt

# NOTE: by default credentials reported back expire in 1 hour:
export AWS_REGION="us-west-2"
export AWS_ACCESS_KEY_ID="$(cat /tmp/tmpcreds.txt| jq -r ".Credentials.AccessKeyId")"
export AWS_SECRET_ACCESS_KEY="$(cat /tmp/tmpcreds.txt| jq -r ".Credentials.SecretAccessKey")"
export AWS_SESSION_TOKEN="$(cat /tmp/tmpcreds.txt | jq -r ".Credentials.SessionToken")"

aws s3 cp hello.txt s3://sliderule-tacolab/hello.txt
```

```
aws sts assume-role --role-arn arn:aws:iam::118211588532:role/sliderule-read  --role-session-name sliderule-read-scott

aws s3 cp s3://sliderule-tacolab/hello.txt hello.txt
```