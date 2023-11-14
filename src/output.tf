# output "ecs-cluster-id" {
#   description = "ECS Cluster ID"
#   value = aws_ecs_cluster.ecs-cluster.id
# }

output "ecr-repository-url" {
  description = "ECR Repository URL "
  value       = aws_ecrpublic_repository.ecr-public-repository.repository_uri
}
