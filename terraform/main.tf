locals {
  # Convention : <resource>-<region>-<environment>
  NAMING_SUFFIX = "${var.AWS_REGION}-${var.ENVIRONMENT}"
}

# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

# Create subnets within the VPC
resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
}

# Create security group for RDS
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.my_vpc.id

  # Define ingress rule to allow MySQL connections from ECS instances
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  # Add more ingress/egress rules as needed
}

# Create Container Registry Repository
resource "aws_ecr_repository" "ecr_repository" {
  name                 = "ecr-repository-${local.NAMING_SUFFIX}"
  image_tag_mutability = "MUTABLE"

  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    "ENVIRONMENT" = var.ENVIRONMENT,
    "REGION"      = var.AWS_REGION
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster-${local.NAMING_SUFFIX}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    "ENVIRONMENT" = var.ENVIRONMENT,
    "REGION"      = var.AWS_REGION
  }
}
# Define ECS task definition for PrestaShop using the ECR image and RDS database connection details
resource "aws_ecs_task_definition" "prestashop_task_definition" {
  family = "prestashop-task-family"
  container_definitions = jsonencode([
    {
      name  = "prestashop-container-${local.NAMING_SUFFIX}"
      image = aws_ecr_repository.ecr_repository.repository_url # ECR image URI
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ],
      environment = [
        {
          name  = "DB_SERVER"
          value = aws_db_instance.rds.endpoint # RDS endpoint
        },
        {
          name  = "DB_USERNAME"
          value = aws_db_instance.rds.username # RDS username
        },
        {
          name  = "DB_PASSWORD"
          value = aws_db_instance.rds.password # RDS password
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.rds.db_name # RDS database name
        },
      ]
      # Add other PrestaShop container configurations if needed
    }
  ])
  # Add other task definition configurations as needed

  tags = {
    "ENVIRONMENT" = var.ENVIRONMENT,
    "REGION"      = var.AWS_REGION
  }
}

# Create RDS instance
resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  db_name              = var.DB_NAME
  username             = var.DB_USERNAME
  password             = var.DB_PASSWORD
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    "ENVIRONMENT" = var.ENVIRONMENT,
    "REGION"      = var.AWS_REGION
  }
}

resource "aws_ecs_service" "prestashop_service" {
  name            = "prestashop-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.prestashop_task_definition.arn
  launch_type     = "EC2"
  desired_count   = 1
  # Add more service configurations if needed

  tags = {
    "ENVIRONMENT" = var.ENVIRONMENT,
    "REGION"      = var.AWS_REGION
  }
}

# Create Application Load Balancer (ALB)
resource "aws_lb" "prestashop_lb" {
  name               = "prestashop-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = ["subnet-12345678", "subnet-87654321"] # Specify your subnets

  enable_deletion_protection = false
}

# Define HTTPS listener for ALB
resource "aws_lb_listener" "prestashop_https_listener" {
  load_balancer_arn = aws_lb.prestashop_lb.arn
  port              = 443
  protocol          = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prestashop_target_group.arn
  }

  certificate_arn = "your_certificate_arn" # Replace with your SSL certificate ARN
}

# Define target group for ECS service
resource "aws_lb_target_group" "prestashop_target_group" {
  name     = "prestashop-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "your_vpc_id" # Replace with your VPC ID
}

# Attach ECS service to target group
resource "aws_lb_target_group_attachment" "prestashop_lb_attachment" {
  target_group_arn = aws_lb_target_group.prestashop_target_group.arn
  target_id        = aws_ecs_service.prestashop_service.id
  port             = 80
}

# Autoscaling for the ECS service based on CPU utilization
resource "aws_appautoscaling_target" "prestashop_scaling_target" {
  max_capacity       = 5 # Maximum number of tasks
  min_capacity       = 1 # Minimum number of tasks
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.id}/${aws_ecs_service.prestashop_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs-${local.NAMING_SUFFIX}"
}

resource "aws_appautoscaling_policy" "prestashop_scaling_policy" {
  name               = "ecs-autoscale-policy-${local.NAMING_SUFFIX}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.prestashop_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.prestashop_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.prestashop_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
    target_value       = 50.0
  }
}

resource "aws_cloudwatch_metric_alarm" "prestashop_scaling_alarm" {
  alarm_name          = "ecs-autoscale-alarm-${local.NAMING_SUFFIX}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_appautoscaling_policy.prestashop_scaling_policy.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.prestashop_service.name
  }
}
