resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.public.id
}

# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Create subnets within the VPC
resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "${var.AWS_REGION}a"
}

# Create subnets within the VPC
resource "aws_subnet" "subnet_2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "${var.AWS_REGION}b"
}

# Create a DB subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]

  tags = {
    "ENVIRONMENT" = var.ENVIRONMENT,
    "REGION"      = var.AWS_REGION
  }
}


# Create Application Load Balancer (ALB)
resource "aws_lb" "prestashop_lb" {
  name               = "prestashop-lb"
  internal           = false
  load_balancer_type = "gateway"
  subnets            = ["${aws_subnet.subnet_1.id}", "${aws_subnet.subnet_2.id}"]

  enable_deletion_protection = false
}

# ALB HTTPS listener using the ACM certificate
resource "aws_lb_listener" "prestashop_http_listener" {
  load_balancer_arn = aws_lb.prestashop_lb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prestashop_target_group.arn
  }
}

# Define target group for ECS service
resource "aws_lb_target_group" "prestashop_target_group" {
  name        = "prestashop-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc.id
}

# Attach ECS service to target group
resource "aws_lb_target_group_attachment" "prestashop_lb_attachment" {
  target_group_arn = aws_lb_target_group.prestashop_target_group.arn
  target_id        = aws_ecs_service.prestashop_service.id
  port             = 80
}

