# resource "aws_ecs_cluster" "ecs-cluster" {
#   name = "test-ecs-cluster"

#   setting {
#     name  = "containerInsights"
#     value = "enabled"
#   }

#   tags = {
#     "ENVIRONMENT" = var.ENVIRONMENT
#   }
# }


# resource "aws_autoscaling_group" "autoscale-group" {
#   # 3 Regions to provide High Availability (free tier)
#   availability_zones = ["${var.LOCATION}a", "${var.LOCATION}b", "${var.LOCATION}c"]
#   desired_capacity = (
#     var.ENVIRONMENT == "dev" ? 1 :
#     var.ENVIRONMENT == "rec" ? 1 :
#   var.ENVIRONMENT == "prod" ? 3 : 1)
#   max_size = 10
#   min_size = 1

#   mixed_instances_policy {
#     launch_template {
#       launch_template_specification {
#         launch_template_id = aws_launch_template.launch-template.id
#       }

#       # No on-demand instances or mixed (free tier)
#     }
#   }
# }

# resource "aws_imagebuilder_container_recipe" "imagebuilder-container-recipe" {
#   name    = "imagebuilder-container-recipe-hash5"
#   version = "1.0.0"

#   container_type = "DOCKER"
#   parent_image   = "arn:aws:imagebuilder:eu-central-1:aws:image/amazon-linux-x86-latest/x.x.x"

#   target_repository {
#     repository_name = aws_ecr_repository.example.name
#     service         = "ECR"
#   }

#   component {
#     component_arn = aws_imagebuilder_component.example.arn

#     parameter {
#       name  = "Parameter1"
#       value = "Value1"
#     }

#     parameter {
#       name  = "Parameter2"
#       value = "Value2"
#     }
#   }
# }

resource "aws_ecrpublic_repository" "ecr-public-repository" {
  repository_name = "ecr-hash5-${var.ENVIRONMENT}"

  catalog_data {
    about_text        = "Should contain Prestashop image from Docker Hub to be used by ECR"
    description       = "Description"
    operating_systems = ["Linux"]
  }

  tags = {
    ENVIRONEMENT = var.ENVIRONMENT
    LOCATION     = var.AWS_REGION
  }
}

# resource "aws_launch_template" "launch-template" {
#   name_prefix = "prestashop-ecs"
#   image_id    = var.IMAGE_ID

#   # Same instance type for all environements (free tier)
#   instance_type = (
#     var.ENVIRONEMENT == "dev" ? var.INSTANCE_TYPE :
#     var.ENVIRONEMENT == "rec" ? var.INSTANCE_TYPE :
#   var.ENVIRONEMENT == "prod" ? var.INSTANCE_TYPE : var.INSTANCE_TYPE)

#   tags = {
#     "ENVIRONMENT" = var.ENVIRONMENT
#   }
# }

# resource "aws_ecs_capacity_provider" "ecs-capacity-provider" {
#   name = "ecs-capacity-provider-hash5"

#   auto_scaling_group_provider {
#     auto_scaling_group_arn         = aws_autoscaling_group.autoscale-group.arn
#     managed_termination_protection = "ENABLED"

#     managed_scaling {
#       maximum_scaling_step_size = 3
#       minimum_scaling_step_size = 1
#       status                    = "ENABLED"
#       target_capacity           = 10
#     }
#   }
#   tags = {
#     "ENVIRONMENT" = var.ENVIRONEMENT
#   }
# }

