resource "aws_security_group" "ecs_service_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = var.load_balancers_sg
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_service_sg"
  }
}

resource "aws_iam_role" "execution_role" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = ""
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "infra" = "ecs"
    "name"  = "ecs-execution-role"
  }
}

resource "aws_iam_role" "task_role" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = ""
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "infra" = "ecs"
    "name"  = "ecs-task-role"
  }
}

resource "aws_iam_policy" "ecr_readonly_policy" {
  name        = "ECRReadOnlyPolicy"
  description = "Allows read-only access to Amazon ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ],
        Resource = "*",
      },
    ],
  })

  tags = {
    "infra" = "ecs"
    "name"  = "ECRReadOnlyPolicy"
  }
}

resource "aws_iam_policy" "cloudwatch_logs_policy" {
  name        = "CloudWatchLogsPolicy"
  description = "Allows access to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Resource = "*",
      },
    ],
  })

  tags = {
    "infra" = "ecs"
    "name"  = "CloudWatchLogsPolicy"
  }
}

resource "aws_iam_role_policy_attachment" "execution_role_ecr_policy_attachment" {
  policy_arn = aws_iam_policy.ecr_readonly_policy.arn
  role       = aws_iam_role.execution_role.name
}

resource "aws_iam_role_policy_attachment" "execution_role_logs_policy_attachment" {
  policy_arn = aws_iam_policy.cloudwatch_logs_policy.arn
  role       = aws_iam_role.execution_role.name
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_cluster"
  }
}
