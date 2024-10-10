/*data "http" "ipinfo" {
  url = "https://ipinfo.io"
}*/
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/28"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.base_name}_vpc"
  }
}
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/29"
  availability_zone = "us-east-2a"
  tags = {
    Name = "${var.base_name}_private_subnet"
  }
}
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.8/29"
  availability_zone = "us-east-2b"
  tags = {
    Name = "${var.base_name}_public_subnet"
  }
}
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.base_name}_internet_gateway"
  }
}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.base_name}_public_route_table"
  }
}
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = var.nat_instance_id
  }

  tags = {
    Name = "${var.base_name}_private_route_table"
  }
}
resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}
locals {
  common_ingress_rules=[
    {
      from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    },
    {
          from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port=22
      to_port=22
      protocol="tcp"
      cidr_blocks=["10.0.0.0/29"]
    }
  ]
}
resource "aws_security_group" "pvt_sec_group" {
  name        = "pvt_sec_group"
  description = "Allow all access for private instances"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

 dynamic "ingress" {
    for_each = [for rule in local.common_ingress_rules : rule if rule.from_port == 22]
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.base_name}_${this.name}"
  }
}
resource "aws_security_group" "nat_sec_group" {
  name        = "nat_sec_group"
  description = "Allow specific access for nat instance"
  vpc_id      = aws_vpc.vpc.id
 dynamic "ingress" {
    for_each = [for rule in local.common_ingress_rules : rule if rule.from_port != 22]
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
   tags = {
    Name = "${var.base_name}_${this.name}"
  }
}

resource "aws_security_group" "web_sec_group" {
  name = "web_sec_group"
  description = "Allow specific access for web server"
  vpc_id = aws_vpc.vpc.id
  dynamic "ingress" {
    for_each = local.common_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  ingress {
    from_port = 10250
    to_port = 10250
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/29"]
  }
  ingress {
    from_port = 10256
    to_port = 10256
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/29"]
  }
  tags = {
    Name = "${var.base_name}_${this.name}"
  }
}