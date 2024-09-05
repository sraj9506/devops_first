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

resource "aws_instance" "ecommerce_instance" {
  count = length(var.instance_prefix)
  ami = "ami-085f9c64a9b75eed5"
  instance_type = count.index==0?"t2.medium":"t2.micro"
  vpc_security_group_ids = [var.security_group_id]
  subnet_id = var.subnet_id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name = "my-key"
  tags = {
    Name = "${var.base_name}_${var.instance_prefix[count.index]}_instance"
    App = var.base_name
  }
}
