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
export AWS_ACCESS_KEY_ID="EXAMPLE"
export AWS_SECRET_ACCESS_KEY="EXAMPLE"
export AWS_REGION="EXAMPLE"
```

### Deploy Terraform backend using AWS cli

```bash
aws s3 mb s3://bucketDev --region us-west-2
# OR
aws s3 mb s3://bucketStaging --region us-west-2
# OR

aws s3 mb s3://bucketProd --region us-west-2
```


<ec2-autoscale-group->

https://hub.docker.com/r/prestashop/prestashop/