locals {
  # Convention : <resource>-<region>-<environment>
  NAMING_SUFFIX = "${var.AWS_REGION}-${var.ENVIRONMENT}"
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
      name      = "prestashop-container-${local.NAMING_SUFFIX}"
      image     = "${aws_ecr_repository.ecr_repository.repository_url}:prestashop"
      cpu       = 3
      memory    = 512
      essential = true
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

  # placement_constraints {
  #   type       = "memberOf"
  #   expression = "attribute:ecs.availability-zone in [${var.AWS_REGION}a, ${var.AWS_REGION}b]"
  # }

  tags = {
    "ENVIRONMENT" = var.ENVIRONMENT,
    "REGION"      = var.AWS_REGION
  }
}

resource "aws_ecs_service" "prestashop_service" {
  name            = "prestashop-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.prestashop_task_definition.arn

  desired_count = 2

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

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    "ENVIRONMENT" = var.ENVIRONMENT,
    "REGION"      = var.AWS_REGION
  }
}
