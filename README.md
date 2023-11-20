# 5HASH - Taylor Shift's Ticket Shop

## Projects Needs

Determine the services needed to match the following needs :

- Deploy Prestashop docker image from Docker Hub to AWS (-> Azure) and include a database (-> MySQL).
- Ensure the app is hosted and ready to handle a huge traffic. (Apache benchmark ?)
- Prioritize scalability and reliability.
- Provide README.md documentation.
- Estimate the base cost and variables from autoscale of the infrastructure.

## Prerequisites

You must consider the `ENVIRONMENT` variable in the following configuration as your project environment.
The following environment are accepted : `dev`, `rec`, `prod`. The terraform configuration will match the differents criteria of the infrastructure depending the chosen environment.

### Connect to AZ-CLI and select your subscription

```bash
# Login to Azure
az login

# Show the account 
az account show

# Set the right subscription key
az account set --subscription <my-subscription>
```

### Create environment variables file inside the terraform folder : variables.tfvars (should be masked if contain sensitive value)

```bash
# For the terraform configuration
PROJECT_NAME="5hash"
ENVIRONMENT="dev"
LOCATION="northeurope"
RESOURCE_GROUPE_NAME="rg-5hash-dev-northeurope"
```

### Deploy Terraform backend to Azure in storage account (default to westeurope because inavailable in northeurope)

Create the following environment variables matching your environment

```bash
# For the backend 
TF_CONTAINER_NAME=tfstate
TF_LOCATION=northeurope
TF_LOCATION_STORAGE=westeurope
ENVIRONMENT=dev
PROJECT_NAME=5hash
RESOURCE_GROUP_NAME=rg-$PROJECT_NAME-$ENVIRONMENT-$TF_LOCATION
TF_STORAGE_ACCOUNT_NAME=$TF_CONTAINER_NAME$PROJECT_NAME$ENVIRONMENT
```

Those commands create the resource group in Azure and prepare a storage account to hold the shared tfstate of our environment.

```bash
# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $TF_LOCATION --tags project=$PROJECT_NAME environment=$ENVIRONMENT

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $TF_STORAGE_ACCOUNT_NAME --location $TF_LOCATION_STORAGE --min-tls-version TLS1_2 --kind StorageV2 --sku Standard_LRS --encryption-services blob --allow-blob-public-access false --https-only true --tags project=$PROJECT_NAME environment=$ENVIRONMENT

# Create blob container
az storage container create --name $TF_CONTAINER_NAME --account-name $TF_STORAGE_ACCOUNT_NAME

# Cleaning up the resource group and storage account
# az group delete --name $RESOURCE_GROUP_NAME --yes --no-wait
# az storage account delete --name $TF_STORAGE_ACCOUNT_NAME --yes
```

### Access the backend later with the terraform file inside the terraform folder : backend.tfvars (should be masked if contain sensitive value)
```bash
resource_group_name  = "rg-5hash-dev-northeurope"
storage_account_name = "tfstate5hashdev"
container_name       = "tfstate"
key                  = "terraform.tfstate"
```

## Start deploying

### Terraform commands

```bash
# Enter the terraform folder
cd terraform

# Provision the infrastructure
terraform init -backend-config="backend.tfvars"
terraform plan -var-file="variables.tfvars" -var-file="backend.tfvars" -out="plan.tfplan"
terraform apply "plan.tfplan"

# This command destroy the Terraform configuration
terraform destroy -var-file="variables.tfvars" -var-file="backend.tfvars"
```

### Add images to Azure Container Registry

You must have Docker running for this part.

```bash
# Set the ACR_NAME as environment variable
ACR_NAME=acr5hashdevnortheurope

# Login to the registry
az acr login -n $ACR_NAME

# Build and Push the images from Docker Hub to the Azure Registry
az acr import --name $ACR_NAME --source docker.io/prestashop/prestashop:latest --image prestashop:latest
```

### Deploy the Kubernetes configuration with Kustomize

```bash
# Move to Kubernetes folder
cd kubernetes
# Set your environment variables if not already done
ENVIRONMENT=dev
RESOURCE_GROUP_NAME=rg-5hash-dev-northeurope
AKS_NAME=aks-5hash-dev-northeurope

# Get cluster credentials
az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $AKS_NAME --overwrite-existing

# Attach Cluster To ACR
az aks update -n aks-5hash-dev-northeurope -g rg-5hash-dev-northeurope --attach-acr acr5hashdevnortheurope

# Download the ingress-nginx chart

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Deploy the ingress controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace --namespace app \
  --set controller.replicaCount=3  \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set controller.service.externalTrafficPolicy=Local
# OR
helm install ingress-nginx ingress-nginx/ingress-nginx --create-namespace --namespace app --set controller.replicaCount=3 --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz --set controller.service.externalTrafficPolicy=Local

# To uninstall ingress-nginx use this command :
helm uninstall ingress-nginx -n app

# Apply Kubernetes configuration with Kustomization
kubectl apply -k ./overlays/$ENVIRONMENT

# Delete configuration
kubectl delete -k  ./kubernetes/overlays/$ENVIRONMENT
```

## Access the Public IP Cluster

```bash
# Get ingress controller public IP
kubectl --namespace app get services ingress-nginx-controller | awk '{print $4}' | tail -n 1
```