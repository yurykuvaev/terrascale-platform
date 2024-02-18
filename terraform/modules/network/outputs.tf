output "vpc_id" {
  description = "The VPC ID."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The primary CIDR block of the VPC."
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of the private (workload) subnets."
  value       = module.vpc.private_subnets
}

output "intra_subnet_ids" {
  description = "IDs of the intra (no-NAT) subnets."
  value       = module.vpc.intra_subnets
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways."
  value       = module.vpc.natgw_ids
}

output "azs" {
  description = "Availability zones the VPC spans."
  value       = module.vpc.azs
}
