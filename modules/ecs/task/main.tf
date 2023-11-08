resource "aws_lb_target_group" "lb_target_group" {
  name        = var.target_group_name
  port        = var.listener_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 60
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = var.lb_arn
  port              = var.listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}


resource "aws_ecs_task_definition" "authorization_task_definition" {
  family                   = var.task_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.cpu
  memory = var.memory

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

  container_definitions = jsonencode([
    {
      "name" : var.container_name,
      "image" : "${var.ecr_repository_url}:${var.image_name}",
      "portMappings" : [
        {
          "containerPort" : var.container_port,
          "protocol" : "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "authorization_ecs_service" {
  name            = var.ecs_service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.authorization_task_definition.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"


  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = [var.subnet_private_a_id, var.subnet_private_b_id]
    security_groups  = [var.ecs_service_sg_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
}
