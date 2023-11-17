# Create security group for ECS
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.vpc.id

  # Define ingress rule to allow traffic from ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Add more ingress/egress rules as needed
}

# Create security group
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.vpc.id

  # Define ingress rule to allow MySQL connections from ECS instances
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  # Add more ingress/egress rules as needed
}

# Create security group for ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.vpc.id

  # Allow inbound HTTP traffic (port 80) from anywhere (0.0.0.0/0) for the ALB
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Add more ingress/egress rules as needed for your specific requirements
}
