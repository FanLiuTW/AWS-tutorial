terraform {
  backend "s3" {
    bucket         = ""
    key            = "infra-lab/dev/ec2/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
