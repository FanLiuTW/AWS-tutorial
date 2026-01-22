variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "allowed_ssh_cidr" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type = string
}

variable "public_key_path" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
