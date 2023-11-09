resource "aws_launch_template" "ami-launch-template" {
  name_prefix   = "foobar"
  image_id      = "ami-05c13eab67c5d8861"
  instance_type = (
    var.ENVIRONEMENT == "dev" ? "t2.micro" :
    var.ENVIRONEMENT == "rec" ? "t2.micro" : 
    var.ENVIRONEMENT == "prod" ? "t2.medium" : none)
}

resource "aws_autoscaling_group" "autoscale-group" {
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e"]
  desired_capacity   = (
    var.ENVIRONEMENT == "dev" ? 1 :
    var.ENVIRONEMENT == "rec" ? 1 :
    var.ENVIRONEMENT == "prod" ? 3 : none)
  max_size           = 10
  min_size           = 1

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ami-launch-template.id
      }

      override {
        instance_type     = "t2.medium"
        weighted_capacity = "1"
      }
    }
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
}

resource "aws_ecs_cluster" "ecs-cluster" {
  name = "test-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
