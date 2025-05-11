locals {
  environment = "staging"
  region      = "us-east-1"

  vpc_cidr             = "10.20.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.20.0.0/22", "10.20.4.0/22", "10.20.8.0/22"]
  private_subnet_cidrs = ["10.20.16.0/20", "10.20.32.0/20", "10.20.48.0/20"]
  intra_subnet_cidrs   = ["10.20.64.0/24", "10.20.65.0/24", "10.20.66.0/24"]

  cluster_name = "terrascale-staging"
}
