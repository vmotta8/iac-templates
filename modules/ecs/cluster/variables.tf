variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID."
  type        = string
}

variable "load_balancers_sg" {
  description = "The load balancers security group ID."
  type        = list(string)
}
