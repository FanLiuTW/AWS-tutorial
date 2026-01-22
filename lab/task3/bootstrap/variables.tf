variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "tfstate_bucket_name" {
  type = string
}

variable "dynamodb_lock_table_name" {
  type    = string
  default = "terraform-locks"
}
