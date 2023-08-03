# Olive Iron

## Project Contents
### Terraform
 - Amazon EKS cluster
 - VPC
 - Intenet Gateway
 - 3 public subnets across 3 AZs
 - 3 private subnets across 3 AZs

## Installing From Scratch
### Create Infra
```console
cd terraform
terraform init
terraform apply -var-file olive-iron.tfvars
```

Note: Terraform apply runs about 9 minutes
Note: Terraform destroy is about 10 minutes

Todo: Investigate this error on terraform delete
```console
│ Error: deleting EKS Cluster (olive_iron): ResourceInUseException: Cluster has nodegroups attached
```

### Cluster
Get the cluster config. The `<project>` will be the project name you set in your [Terraform Vars](terraform/olive-iron.tfvars)
```bash
cp ~/.kube/config ~/.kube/config.bak # awscli will overwrite a file if it's there
aws eks update-kubeconfig --region us-east-2 --name <project>
```
More details on kubeconfig generation on [AWS's Docs](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html)