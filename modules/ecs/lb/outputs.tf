output "lb_arn" {
  value = aws_lb.load_balancer.arn
}

output "lb_sg_id" {
  value = aws_security_group.lb_sg.id
}
