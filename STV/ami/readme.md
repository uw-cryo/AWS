# Use packer to create Amazon Machie Image with software pre-installed

https://developer.hashicorp.com/packer/tutorials/aws-get-started/get-started-install-cli

```
packer init .
packer validate .
packer fmt .
packer build .
```

==> Wait completed after 11 minutes 12 seconds

==> Builds finished. The artifacts of successful builds are:
--> stv-dart-builder.amazon-ebs.ubuntu: AMIs were created:
us-west-2: ami-063d104f518c8623e


Remove it if you want (or rename if building another)
```
aws ec2 deregister-image --image-id ami-063d104f518c8623e --region us-west-2
aws ec2 delete-snapshot --snapshot-id snap-0e8d506c0ae409ddb  --region us-west-2 
```