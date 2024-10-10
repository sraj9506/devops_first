data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.bucket_arn}/*"]
    effect = "Allow"
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.base_name}_ec2_instance_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_policy" "s3_access_policy" {
  name = "${var.base_name}_s3_access_policy"
  description = "Policy to allow EC2 instance to read a specific S3 bucket"
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_iam_role_policy_attachment" "s3_read_attachment" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.base_name}_ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "owner-id"
    values = ["099720109477"]
  }
}

data "aws_ami" "nat" {
  most_recent = true
  filter {
    name = "name"
    values = ["amazon/amzn-ami-vpc-nat-*-x86_64-ebs"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "owner-id"
    values = ["137112412989"]
  }
}


resource "aws_instance" "ecommerce_instance" {
  count = length(var.instance_prefix)
  ami = count.index==5?data.aws_ami.nat.id:data.aws_ami.ubuntu.id
  instance_type = count.index==0?"t2.medium":"t2.micro"
  subnet_id = count.index>4?var.public_subnet_id:var.private_subnet_id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [
    count.index<5?var.security_group_ids["private"]:
    count.index==5?var.security_group_ids["nat"]:
    var.security_group_ids["webserver"]
  ]
  key_name = "my-key"
  tags = {
    Name = "${var.base_name}_${var.instance_prefix[count.index]}_instance"
    App = var.base_name
  }
}
