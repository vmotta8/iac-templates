variable "region" {
  description = "AWS region"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository url"
  type        = string
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "subnet_private_a_id" {
  description = "Subnet private a id"
  type        = string
}

variable "subnet_private_b_id" {
  description = "Subnet private b id"
  type        = string
}

variable "lb_arn" {
  description = "Load balancer arn"
  type        = string
}

variable "lb_default_listener_arn" {
  description = "Load balancer default listener arn"
  type        = string
}

variable "task_role_arn" {
  description = "Task role arn"
  type        = string
}

variable "execution_role_arn" {
  description = "Execution role arn"
  type        = string
}

variable "cluster_id" {
  description = "Cluster id"
  type        = string
}

variable "ecs_service_sg_id" {
  description = "The security group ID."
  type        = string
}

variable "task_name" {
  description = "Task name"
  type        = string
}

variable "target_group_name" {
  description = "Target group name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
}

variable "image_name" {
  description = "Image name"
  type        = string
}

variable "container_name" {
  description = "Container name"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "listener_port" {
  description = "Listener port"
  type        = number
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
}

variable "redirect_path" {
  description = "Redirect path"
  type        = string
}

variable "cpu" {
  description = "CPU units"
  type        = string
}

variable "memory" {
  description = "Memory units"
  type        = string
}

variable "desired_count" {
  description = "Desired count"
  type        = number
}
