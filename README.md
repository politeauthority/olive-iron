# Olive Iron
This project creates an AWS EKS cluster with 3 nodes. It servers the application `Hello-Graylog`, along
with monitoring and other minor cluster tooling. Much of the work here is based on my [homelab baremetal cluster](https://github.com/politeauthority/colfax-ops), but was adapted to work with AWS. It takes around 40 minutes to fully launch from the first command.

Thanks for the chance to interview to work with you guys!

## Project Contents
### Terraform
 - Amazon EKS cluster
 - VPC
 - Internet Gateway
 - NAT Gateway
 - Elastic IP
 - 3 public subnets across 3 AZs
 - 3 private subnets across 3 AZs
 - 3 EC2 worker nodes with the machine type `m5.large`
### Applications
 - Argo CD
 - Nginx Ingress
 - Cert Manager
 - Prometheus
 - Grafana
 - Hello Graylog

## Installing From Scratch
### Preflight
Clone and rehost to an available git host, or fork this repo on github.
There are a handful of local tools required to make use of this project. I've included my local versions, however in some instances lower versions may work, and higher versions *should* work.
 - terraform v1.5.4
 - aws-cli v2.8.6
 - kubectl v1.27
 - kustomize v5.1.0
 - helm v3.9.4

### Create the Infrastructure
Create the intial infrastructure. This will deploy our EKS cluster along with all the required
networking. Currenty we're configured to deploy 3 `m5.large` worker nodes.
 - Create a copy of the [olive-iron.tfvars](terraform/olive-iron.tfvars) @todo: Finish this part
```console
cd terraform
terraform init
terraform apply -var-file olive-iron.tfvars
```
ℹ️ Terraform apply runs about 10 minutes

### Create the Cluster Applications
Get the cluster config. The `<region>` and  `<project>` will be the project name you set in your [Terraform Vars](terraform/olive-iron.tfvars)
```bash
cp ~/.kube/config ~/.kube/config.bak # Let's make a back-up, just in case.
aws eks update-kubeconfig --region <region> --name <project>
```
More details on kubeconfig generation on [AWS's Docs](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html)

#### Installing ArgoCD and Initial Apps
Here we will launch ArgoCD, Cert
 - Create the `argocd` namespace and install the base ArgoCD application.
```bash
cd argocd/base
kubectl create ns argocd
kustomize build . | kubectl apply -f -
```
 - Once the ArgoCD services are all up and healthy you should be able to portforward into the ArgoCD server.
   ⚠️ You will have to accept a self signed certificate in order to view the ArgoCD web app.
```bash
kubectl port-forward -n argocd svc/argocd-server 9001:443
```
 - Next we need to add this, or your own repository to the ArgoCD repositories. I did this through the GUI however this could be done via the CLI. You can get the ArgoCD initial admin password by running the following. (This assumes you're using MacOS's base64)
```bash
kc get secrets -n argocd argocd-initial-admin-secret -oyaml | yq .data.password | base64 -D
```
 - Then we will setup ArgoCD to manage it's self, and all the other applications we will be deploying to our cluster. To do this we will run the following (assuming we're at the base of the repo, with the kubectl namespace context of `argocd`).
```bash
cd argocd/
kustomize build . | kubectl apply -f -
```
 - At this point ArgoCD will start auto deployng the following applications.
   - Cert Manager
   - Ingress Nginx
   - Metrics


#### Setup DNS and Ingress
Since the Ingress controller is deployed as a `LoadBalancer` type, we'll need to grab that EC2 Load Balancer address and use that to setup a CNAME record. [External DNS](https://github.com/kubernetes-sigs/external-dns) would be a great tool for this, but for time's sake I've decided to do this part without it.

```bash
DOMAIN="example.com"
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name yourdomain.com --query "HostedZones[0].Id" --output text | sed 's/\/hostedzone\///')
LOAD_BALANCER=$(kubectl get svc -n ingress-public ingresspublic-ingress-nginx-controller -oyaml | yq eval '.status.loadBalancer.ingress[0].hostname')
aws route53 change-resource-record-sets --hosted-zone-id  ${HOSTED_ZONE_ID} --change-batch '{
    "Changes": [
        {
            "Action": "CREATE",
            "ResourceRecordSet": {
                "Name": "*.${DOMAIN}.",
                "Type": "AAAA",
                "AliasTarget": {
                    "DNSName": "${LOAD_BALANCER}",
                    "EvaluateTargetHealth": false,
                    "HostedZoneId": "${HOSTED_ZONE_ID}"
                }
            }
        }
    ]
}'
```

#### Deploy Prometheus-Stack
To enable monitering, we can head over to the ArgoCD app and sync the `prometheusstack` application. Since this
requires working ingress for the https://grafana.alix.lol we wait to do this stage now.

#### Deploy Hello Graylog Application
Once our monitoring stack is up and healthy, we're ready to go back to ArgoCD and sync the `hellograylog` application.
This will deploy the HelloGray log application with HPA and public ingress at https://graylog.alix.lol, and a health check at https://graylog.alix.lol/healthz


## Tear Down
To tear down the entire application and cluster we'll need to run a terraform destroy
```bash
terraform destroy -var-file olive-iron.tfvars
```
⚠️ This will destroy everything **except** for the Elastic Load Balancer, you will need to delete that manually.
