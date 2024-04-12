resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_vpc"
  }
}

resource "aws_subnet" "subnet_public_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_subnet_public_a"
  }
}

resource "aws_subnet" "subnet_public_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_subnet_public_b"
  }
}

resource "aws_subnet" "subnet_private_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_subnet_private_a"
  }
}

resource "aws_subnet" "subnet_private_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.region}b"

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_subnet_private_b"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_public_route_table"
  }
}

resource "aws_route_table_association" "rt_association_public_a" {
  subnet_id      = aws_subnet.subnet_public_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "rt_association_public_b" {
  subnet_id      = aws_subnet.subnet_public_b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table_a" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_network_interface.network_interface_a.id
  }

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_private_route_table_a"
  }
}

resource "aws_route_table" "private_route_table_b" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_network_interface.network_interface_b.id
  }

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_private_route_table_b"
  }
}

resource "aws_route_table_association" "rt_association_private_a" {
  subnet_id      = aws_subnet.subnet_private_a.id
  route_table_id = aws_route_table.private_route_table_a.id
}

resource "aws_route_table_association" "rt_association_private_b" {
  subnet_id      = aws_subnet.subnet_private_b.id
  route_table_id = aws_route_table.private_route_table_b.id
}

resource "aws_security_group" "nat_sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_nat_sg"
  }
}

resource "aws_network_interface" "network_interface_a" {
  subnet_id         = aws_subnet.subnet_public_a.id
  source_dest_check = false
  security_groups   = [aws_security_group.nat_sg.id]

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_network_interface_a"
  }
}

resource "aws_network_interface" "network_interface_b" {
  subnet_id         = aws_subnet.subnet_public_b.id
  source_dest_check = false
  security_groups   = [aws_security_group.nat_sg.id]

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_network_interface_b"
  }
}

resource "aws_instance" "nat_instance_a" {
  ami                  = "ami-0f57d652281755ea1" # fck-nat ami
  instance_type        = var.instance_type
  count                = 1
  key_name             = var.key_pair_name
  iam_instance_profile = aws_iam_instance_profile.nat_instance_profile.name

  network_interface {
    network_interface_id = aws_network_interface.network_interface_a.id
    device_index         = 0
  }

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_nat_instance_a"
  }
}

resource "aws_instance" "nat_instance_b" {
  ami                  = "ami-0f57d652281755ea1" # fck-nat ami
  instance_type        = var.instance_type
  count                = 1
  key_name             = var.key_pair_name
  iam_instance_profile = aws_iam_instance_profile.nat_instance_profile.name

  network_interface {
    network_interface_id = aws_network_interface.network_interface_b.id
    device_index         = 0
  }

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_nat_instance_b"
  }
}

resource "aws_iam_role" "ec2_instance_role" {
  name = "EC2InstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_ec2_instance_role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_instance_profile" "nat_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_nat_instance_profile"
  }
}

resource "aws_service_discovery_http_namespace" "services_http_namespace" {
  name = "service"

  tags = {
    "infra" = "ecs"
    "name"  = "ecs_http_namespace"
  }
}
