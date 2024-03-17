locals {
  environment = "dev"
  region      = "us-east-1"

  # Network sizing for dev. Single NAT to save cost; smaller subnets.
  vpc_cidr             = "10.10.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.10.0.0/22", "10.10.4.0/22", "10.10.8.0/22"]
  private_subnet_cidrs = ["10.10.16.0/20", "10.10.32.0/20", "10.10.48.0/20"]
  intra_subnet_cidrs   = ["10.10.64.0/24", "10.10.65.0/24", "10.10.66.0/24"]

  cluster_name = "terrascale-dev"
}
