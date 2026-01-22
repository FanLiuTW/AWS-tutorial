locals {
  region = "ap-northeast-1"
  common_tags = {
    ManagedBy = "terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF2
provider "aws" {
  region = "${local.region}"
  default_tags {
    tags = ${jsonencode(local.common_tags)}
  }
}
EOF2
}
