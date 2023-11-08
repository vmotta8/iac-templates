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

variable "vpc_cidr_block" {
  description = "The VPC CIDR block."
  type        = string
}

variable "lb_name" {
  description = "The name of the load balancer."
  type        = string
}

variable "subnet_public_a_id" {
  description = "The public subnet A ID."
  type        = string
}

variable "subnet_public_b_id" {
  description = "The public subnet B ID."
  type        = string
}
