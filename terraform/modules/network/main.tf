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
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
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
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
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
  common_rules=[
    
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
      cidr_blocks=["10.0.1.0/28"]
    }
  ]
  common_ingress_rules=[
    
  {
    from_port = 10250
    to_port = 10250
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/29"]
  },
  {
    from_port = 9100
    to_port = 9100
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/29"]
  }
    
  ]
}

resource "aws_security_group" "master_sec_group" {
  name        = "master_sec_group"
  description = "Allow specific access for kube master"
  vpc_id      = aws_vpc.vpc.id
   dynamic "ingress" {
    for_each = local.common_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
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
    from_port = 6443
    to_port = 6443
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/29","10.0.0.8/29"]
  }
    dynamic "egress" {
    for_each = [for rule in local.common_rules : rule if rule.from_port != 22]
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
  tags = {
    Name = "${var.base_name}_${this.name}"
  }
}

resource "aws_security_group" "worker_sec_group" {
  name        = "worker_sec_group"
  description = "Allow specific access for kube workers"
  vpc_id      = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = local.common_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
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
    from_port = 10255
    to_port = 10255
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/29"]
  }
  ingress {
    from_port = 10256
    to_port = 10256
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/29"]
  }
  dynamic "egress" {
    for_each = [for rule in local.common_rules : rule if rule.from_port != 22]
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
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
    for_each = [for rule in local.common_rules : rule if rule.from_port != 22]
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  dynamic "egress" {
    for_each = [for rule in local.common_rules : rule if rule.from_port != 22]
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
   tags = {
    Name = "${var.base_name}_${this.name}"
  }
}

resource "aws_security_group" "prom_sec_group" {
  name = "prom_sec_group"
  description = "Allow specific access for prometheus server"
  vpc_id = aws_vpc.vpc.id
  dynamic "ingress" {
    for_each = local.common_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

    dynamic "egress" {
    for_each = [for rule in local.common_rules : rule if rule.from_port != 22]
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
    ingress {
    from_port = 9090
    to_port = 9090
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/29"]
  }
    tags = {
    Name = "${var.base_name}_${this.name}"
  }
}

data "terraform_remote_state" "jenkins_vpc" {
  backend = "s3"
  config = {
    bucket = "sraj_jenkins_bucket"
    key = "terraform.tfstate"
    region = "us-east-2"
  }

}

resource "aws_vpc_peering_connection" "peer" {
  vpc_id = aws_vpc.vpc.id
  peer_vpc_id = data.terraform_remote_state.jenkins_vpc.outputs.vpc_id
  auto_accept = true
  tags = {
    Name = "${var.base_name}_${this.name}"
  }
}



