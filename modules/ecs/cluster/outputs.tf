output "ecs_service_sg_id" {
  value = aws_security_group.ecs_service_sg.id
}

output "execution_role_arn" {
  value = aws_iam_role.execution_role.arn
}

output "task_role_arn" {
  value = aws_iam_role.task_role.arn
}

output "cluster_id" {
  value = aws_ecs_cluster.ecs_cluster.id
}
