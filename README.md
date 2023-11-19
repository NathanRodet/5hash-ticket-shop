# 5HASH - Taylor Shift's Ticket Shop

## Projects Needs

Determine the services needed to match the following needs :

- Deploy Prestashop docker image from Docker Hub to AWS (-> Azure) and include a database (-> MySQL).
- Ensure the app is hosted and ready to handle a huge traffic. (Apache benchmark ?)
- Prioritize scalability and reliability.
- Provide README.md documentation.
- Estimate the base cost and variables from autoscale of the infrastructure.

## Prerequisites

### Connect to AZ-CLI and select your subscription

```bash
az login
az account show
az account set --subscription <my-subscription>
```

### Create environment variables file : variables.tfvars (should be masked if contain sensitive value)

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
RESOURCE_GROUP_NAME=rg-$PROJECT_NAME-$ENVIRONMENT-$LOCATION
TF_STORAGE_ACCOUNT_NAME=$TF_CONTAINER_NAME$PROJECT_NAME$ENVIRONMENT
```

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

### Access the backend later with the terraform file : backend.tfvars (should be masked if contain sensitive value)
```bash
resource_group_name  = "rg-5hash-dev-northeurope"
storage_account_name = "tfstate5hashdev"
container_name       = "tfstate"
key                  = "terraform.tfstate"
```

## Start deploying

### Terraform commands

```bash
terraform init -backend-config="backend.tfvars"
terraform plan -var-file="variables.tfvars" -var-file="backend.tfvars" -out="plan.tfplan"
terraform apply "plan.tfplan"
terraform destroy -var-file="variables.tfvars" -var-file="backend.tfvars"
```

### Add images to Container Registry

```bash
# Login to the registry
az acr login -n $ACR_LOGIN_SERVER
# Build and Push the images to the registry
az acr import --name acr5hashdevnortheurope --source docker.io/library/prestashop:latest --image prestashop:latest
```