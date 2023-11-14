# 5HASH - Taylor Shift's Ticket Shop

## Projects Needs

Determine the services needed to match the following needs :

- Deploy Prestashop docker image from Docker Hub to AWS and include a database.
- Ensure the app is hosted and ready to handle a huge traffic. (Apache benchmark ?)
- Prioritize scalability and reliability.
- Provide README.md documentation.
- Estimate the base cost and variables from autoscale of the infrastructure.

## Prerequisites

We will see the prerequisites to launch this Terraform configuration across environments.

### Provide AWS credentials to use Terraform and AWS cli

```bash
# Linux
export TF_VAR_AWS_ACCESS_KEY=EXAMPLE
export TF_VAR_AWS_SECRET_KEY=EXAMPLE
export TF_VAR_AWS_REGION=eu-west-1
export TF_VAR_ENVIRONMENT="dev
# Windows
set TF_VAR_AWS_ACCESS_KEY=EXAMPLE
set TF_VAR_AWS_SECRET_KEY=EXAMPLE
set TF_VAR_AWS_REGION=eu-west-1
set TF_VAR_ENVIRONMENT=dev
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