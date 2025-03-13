provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "flask_cluster" {
  name = "flask-cluster"
}

resource "aws_ecs_task_definition" "flask_task" {
  family                   = "flask-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn = "arn:aws:iam::539247453290:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name  = "flask-container"
      image = "539247453290.dkr.ecr.us-east-1.amazonaws.com/flask-app:latest"
      cpu   = 256
      memory = 512
      essential = true
      portMappings = [{ containerPort = 5000, hostPort = 5000 }]
    }
  ])
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-security-group"
  description = "Allow inbound traffic for ECS service"
  vpc_id      = "vpc-002b849219fc628d9"

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from anywhere (update if needed)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
}

resource "aws_ecs_service" "flask_service" {
  name            = "flask-service"
  cluster         = aws_ecs_cluster.flask_cluster.id
  task_definition = aws_ecs_task_definition.flask_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["subnet-01fe890957c28408c"]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

}
