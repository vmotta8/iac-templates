resource "aws_lb_target_group" "lb_target_group_http" {
  count = (var.protocol == "HTTP" || var.protocol == "BOTH") != "" ? 1 : 0

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

  tags = {
    "infra" = "ecs"
    "name"  = "lb_target_group_http"
  }
}

resource "aws_lb_target_group" "lb_target_group_https" {
  count = (var.protocol == "HTTPS" || var.protocol == "BOTH") && var.ssl_certificate_arn != "" ? 1 : 0

  name        = var.target_group_name
  port        = var.listener_port
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = var.health_check_path
    protocol            = "HTTPS"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 60
    matcher             = "200-399"
  }

  tags = {
    "infra" = "ecs"
    "name"  = "lb_target_group_https"
  }
}

resource "aws_lb_listener" "lb_default_listener_http" {
  count = (var.protocol == "HTTP" || var.protocol == "BOTH") != "" ? 1 : 0

  load_balancer_arn = var.lb_arn
  port              = var.listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group_http[0].arn
  }

  tags = {
    "infra" = "ecs"
    "name"  = "lb_default_listener_http"
  }
}

resource "aws_lb_listener" "lb_default_listener_https" {
  count = (var.protocol == "HTTPS" || var.protocol == "BOTH") && var.ssl_certificate_arn != "" ? 1 : 0

  load_balancer_arn = var.lb_arn
  port              = var.listener_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group_https[0].arn
  }

  tags = {
    "infra" = "ecs"
    "name"  = "lb_default_listener_https"
  }
}

resource "aws_cloudwatch_log_group" "task_log_group" {
  name              = "/ecs/${var.task_name}"
  retention_in_days = 1

  tags = {
    "infra" = "ecs"
    "name"  = "task_log_group"
  }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
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
      "image" : "${var.ecr_repository_url}:${var.image_tag}",
      "portMappings" : [
        {
          "containerPort" : var.container_port,
          "protocol" : "tcp",
          "appProtocol" : "http",
          "name" : var.container_name
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.task_log_group.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs"
        }
      },
      "healthCheck" : {
        "retries" : 10,
        "command" : [
          "CMD-SHELL",
          "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"
        ],
        "timeout" : 5,
        "interval" : 10,
        "startPeriod" : 30
      },
      "environment" : [
        for key, value in var.envs_variables : {
          name  = key
          value = value
        }
      ]
    }
  ])

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_task_definition"
  }
}

resource "aws_cloudwatch_log_group" "service_connect_log_group" {
  name              = "/sc/${var.task_name}"
  retention_in_days = 1

  tags = {
    "infra" = "ecs"
    "name"  = "service_connect_log_group"
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = var.ecs_service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"


  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets         = [var.subnet_private_a_id, var.subnet_private_b_id]
    security_groups = [var.ecs_service_sg_id]
  }

  service_connect_configuration {
    enabled   = true
    namespace = var.http_namespace_arn
    service {
      discovery_name = var.discovery_name
      port_name      = var.container_name
      client_alias {
        dns_name = "${var.discovery_name}.service"
        port     = var.container_port
      }
    }

    log_configuration {
      log_driver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.service_connect_log_group.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "sc"
      }
    }
  }

  dynamic "load_balancer" {
    for_each = var.protocol == "HTTP" || var.protocol == "BOTH" ? [aws_lb_target_group.lb_target_group_http[0]] : []
    content {
      target_group_arn = load_balancer.value.arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  dynamic "load_balancer" {
    for_each = var.protocol == "HTTPS" || var.protocol == "BOTH" && var.ssl_certificate_arn != "" ? [aws_lb_target_group.lb_target_group_https[0]] : []
    content {
      target_group_arn = load_balancer.value.arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_service"
  }
}
