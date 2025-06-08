locals {
  environment = "prod"
  region      = "us-east-1"

  vpc_cidr             = "10.30.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.30.0.0/22", "10.30.4.0/22", "10.30.8.0/22"]
  private_subnet_cidrs = ["10.30.16.0/20", "10.30.32.0/20", "10.30.48.0/20"]
  intra_subnet_cidrs   = ["10.30.64.0/24", "10.30.65.0/24", "10.30.66.0/24"]

  cluster_name = "terrascale-prod"
}
