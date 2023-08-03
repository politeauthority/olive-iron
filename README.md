# Olive Iron

## Project Contents
### Terraform
 - Amazon EKS cluster
 - VPC
 - Internet Gateway
 - NAT Gateway
 - Elastic IP
 - 3 public subnets across 3 AZs
 - 3 private subnets across 3 AZs

## Installing From Scratch
### Intial Steps
Clone and rehost to an available git host, or fork this repo on github.
There are a handful of local tools required to make use of this project. I've included my local versions, however in some instances lower versions may work, and higher versions *should* work.
 - Terraform v1.5.4
 - aws-cli v2.8.6
 - kubectl
 - kubeseal
 - kustomize
 - helm

### Create Infra
Create the intial infrastructure. This will deploy our EKS cluster along with all the required
networking. Currenty we're configured to deploy 3 `t3.xlarge` worker nodes.
```console
cd terraform
terraform init
terraform apply -var-file olive-iron.tfvars
```
ℹ️ Terraform apply runs about 12 minutes
ℹ️ Terraform destroy is about 10 minutes

### Cluster
Get the cluster config. The `<region>` and  `<project>` will be the project name you set in your [Terraform Vars](terraform/olive-iron.tfvars)
```bash
cp ~/.kube/config ~/.kube/config.bak # Let's make a back-up, just in case.
aws eks update-kubeconfig --region <region> --name <project>
```
More details on kubeconfig generation on [AWS's Docs](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html)

#### Installing Sealed Secrets
Sealed-Secrets allows us to store secrets in git without them being exposed. Because this is needed for many
ArgoCD projects, we install this outside of ArgoCD, and run the helm install manually. More information on Sealed-Secrets at https://github.com/bitnami-labs/sealed-secrets

##### Installing in the Cluster
```bash
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm install sealed-secrets \
    -n kube-system \
    --set-string fullnameOverride=sealed-secrets-controller \
    sealed-secrets/sealed-secrets
```
ℹ️ Existing secrets will have to be regenerated anytime the KubeSeal controller is brought in new to a cluster.

##### Creating a Sealed Secret
```bash
kubectl \
    create secret generic \
    <secret-name> \
    --dry-run=client \
    --from-literal=foo=bar -o yaml | \
    kubeseal \
    --controller-name=sealed-secrets-controller \
    --controller-namespace=kube-system \
    --format yaml > mysealedsecret.yaml
```

#### Installing ArgoCD
 - Create the `argocd` namespace and install the base ArgoCD application.
```bash
cd argocd/base
kubectl create ns argocd
kustomize build . | kubectl apply -f -
```
 - Once the ArgoCD services are all up and healthy you should be able to portforward into the ArgoCD server. ⚠️ You will have to accept a self signed certificate in order to view the ArgoCD web app.
```bash
kubectl port-forward svc/argocd-server 9001:443
```
 - Next we need to add this repository to the ArgoCD repositories. I did this through the GUI however this could be done via the CLI.
 - Then we will setup ArgoCD to manage it's self, and all the other applications we will be deploying to our cluster. To do this we will run the following (assuming we're at the base of the repo, with the kubectl namespace context of `argocd`).
```bash
cd argocd/
kustomize build . | kubectl apply -f -
```

# ToDos
 - Spell check README

# Warnings/ Notes
- Cert-manager will get angry with issuers coming in at the same time as the CRDS for issuers
- Ingress LB VS TF LB