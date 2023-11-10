resource "aws_ecs_cluster" "ecs-cluster" {
  name = "test-ecs-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    "ENVIRONMENT" = var.ENVIRONEMENT
  }
}


resource "aws_autoscaling_group" "autoscale-group" {
  # 3 Regions to provide High Availability (free tier)
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  desired_capacity   = (
    var.ENVIRONEMENT == "dev" ? 1 :
    var.ENVIRONEMENT == "rec" ? 1 :
    var.ENVIRONEMENT == "prod" ? 3 : 1)
  max_size           = 10
  min_size           = 1

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.launch-template.id
      }

      # No on-demand instances or mixed (free tier)
    }
  }
}

resource "aws_imagebuilder_container_recipe" "imagebuilder-container-recipe" {
  name    = "example"
  version = "1.0.0"

  container_type = "DOCKER"
  parent_image   = "arn:aws:imagebuilder:eu-central-1:aws:image/amazon-linux-x86-latest/x.x.x"

  target_repository {
    repository_name = aws_ecr_repository.example.name
    service         = "ECR"
  }

  component {
    component_arn = aws_imagebuilder_component.example.arn

    parameter {
      name  = "Parameter1"
      value = "Value1"
    }

    parameter {
      name  = "Parameter2"
      value = "Value2"
    }
  }
}

resource "aws_ecr_repository" "ecr-repository" {
  name                 = "bar"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true
}

resource "aws_launch_template" "launch-template" {
  name_prefix   = "foobar"
  image_id      = var.IMAGE_ID

  # Same instance type for all environements (free tier)
  instance_type = (
    var.ENVIRONEMENT == "dev" ? var.INSTANCE_TYPE :
    var.ENVIRONEMENT == "rec" ? var.INSTANCE_TYPE : 
    var.ENVIRONEMENT == "prod" ? var.INSTANCE_TYPE : var.INSTANCE_TYPE)

  tags = {
    "ENVIRONMENT" = var.ENVIRONEMENT
  }
}

resource "aws_ecs_capacity_provider" "ecs-capacity-provider" {
  name = "test-ecs-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.autoscale-group.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 3
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 10
    }
  }
  tags = {
    "ENVIRONMENT" = var.ENVIRONEMENT
  }
}

