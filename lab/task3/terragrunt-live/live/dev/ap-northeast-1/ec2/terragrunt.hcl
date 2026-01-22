terraform {
  source = "../../../../modules/ec2"
}

inputs = {
  project          = "infra-lab"
  env              = "dev"
  aws_region       = "ap-northeast-1"
  allowed_ssh_cidr = ""
  instance_type    = "t3.micro"
  key_name         = "infra-lab-dev-key"
  public_key_path  = ""
  tags = {
    Owner = ""
    Env   = "dev"
  }
}

remote_state {
  backend = "s3"
  config = {
    bucket         = ""
    key            = "infra-lab/dev/ec2/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
