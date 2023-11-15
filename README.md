# 5HASH - Taylor Shift's Ticket Shop

## Projects Needs

Determine the services needed to match the following needs :

- Deploy Prestashop docker image from Docker Hub to AWS and include a database.
- Ensure the app is hosted and ready to handle a huge traffic. (Apache benchmark ?)
- Prioritize scalability and reliability.
- Provide README.md documentation.
- Estimate the base cost and variables from autoscale of the infrastructure.

## Prerequisites and setup

We will see the prerequisites to launch this Terraform configuration across environments.

### Configure AWS CLI

```bash
# Credentials and data to provide : access_key, secret_key, region
aws configure
```

### Provide AWS credentials to use Terraform

```bash
# Linux
export TF_VAR_AWS_ACCESS_KEY=
export TF_VAR_AWS_SECRET_KEY
export TF_VAR_AWS_REGION=eu-west-1
export TF_VAR_ENVIRONMENT=dev
```

### Deploy Terraform backend using AWS cli

```bash
aws s3 mb s3://bucketDev --region eu-west-1
# OR
aws s3 mb s3://bucketStaging --region eu-west-1
# OR
aws s3 mb s3://bucketProd --region eu-west-1
```

### Terraform to deploy environments
 
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan -auto-approve
```

### Login to ECR

The url of the ECR can be found in the terraform output after creation

```bash
# URL can also be found here : aws ecr describe-repositories
export AWS_DOCKER_REPOSITORY_URI=210878325243.dkr.ecr.eu-west-1.amazonaws.com/ecr-repository-eu-west-1-dev
aws ecr get-login-password --region $TF_VAR_AWS_REGION | docker login --username AWS --password-stdin $AWS_DOCKER_REPOSITORY_URI
```

### Push the images to ECR

```bash
docker pull prestashop/prestashop:latest
docker tag prestashop/prestashop "$AWS_DOCKER_REPOSITORY_URI/prestashop:aws-latest"
docker push "$AWS_DOCKER_REPOSITORY_URI/prestashop:aws-latest"
# docker rmi prestashop/prestashop "$AWS_DOCKER_REPOSITORY_URI/prestashop:aws-latest"
```

### Create image for AWS public ECR

source: https://docs.aws.amazon.com/AmazonECR/latest/public/docker-push-ecr-image.html
source: https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html 
```bash
# Linux
docker pull prestashop/prestashop:latest
docker tag prestashop/prestashop public.ecr.aws/prestashop-ecs-$TF_VAR_ENVIRONMENT/prestashop:aws-latest
docker push public.ecr.aws/prestashop-ecs-$TF_VAR_ENVIRONMENT/prestashop:aws-latest
# docker rmi prestashop/prestashop public.ecr.aws/prestashop-ecs-$TF_VAR_ENVIRONMENT/prestashop:aws-latest

# Windows
docker pull prestashop/prestashop:latest
docker tag prestashop/prestashop public.ecr.aws/prestashop-ecs-%TF_VAR_ENVIRONMENT%/prestashop:aws-latest
docker push public.ecr.aws/prestashop-ecs-%TF_VAR_ENVIRONMENT%/prestashop:aws-latest
# docker rmi prestashop/prestashop public.ecr.aws/prestashop-ecs-%TF_VAR_ENVIRONMENT%/prestashop:aws-latest
```

<ec2-autoscale-group->

https://hub.docker.com/r/prestashop/prestashop/