data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

terraform {
  backend "s3" {}
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  public_key_path = startswith(var.public_key_path, "/") ? var.public_key_path : "${path.root}/${var.public_key_path}"
}

resource "aws_security_group" "ssh" {
  name        = "${var.project}-${var.env}-ssh"
  description = "Allow SSH access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-ssh"
  })
}

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = file(local.public_key_path)

  tags = merge(var.tags, {
    Name = var.key_name
  })
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = aws_key_pair.this.key_name

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-ec2"
  })
}
