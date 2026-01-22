module "ec2" {
  source           = "../../modules/ec2"
  project          = var.project
  env              = var.env
  aws_region       = var.aws_region
  allowed_ssh_cidr = var.allowed_ssh_cidr
  instance_type    = var.instance_type
  key_name         = var.key_name
  public_key_path  = var.public_key_path
  tags             = var.tags
}
