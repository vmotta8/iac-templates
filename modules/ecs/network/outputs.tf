output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.vpc.cidr_block
}

output "subnet_public_a_id" {
  value = aws_subnet.subnet_public_a.id
}

output "subnet_public_b_id" {
  value = aws_subnet.subnet_public_b.id
}

output "subnet_private_a_id" {
  value = aws_subnet.subnet_private_a.id
}

output "subnet_private_b_id" {
  value = aws_subnet.subnet_private_b.id
}

output "services_http_namespace_arn" {
  value = aws_service_discovery_http_namespace.services_http_namespace.arn
}
