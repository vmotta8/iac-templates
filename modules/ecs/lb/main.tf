resource "aws_security_group" "lb_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_lb_sg"
  }
}

resource "aws_lb" "load_balancer" {
  name               = var.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [var.subnet_public_a_id, var.subnet_public_b_id]

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_lb"
  }
}
