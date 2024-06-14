module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>3.12"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 6, k * 4)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k * 4 + 64)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k * 4 + 128)]

  enable_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    "karpenter.sh/discovery" = local.name
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.name
  }

  tags = local.tags
}

##

# Create VPC peering connection between the existing VPC and the new VPC
resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id      = data.aws_vpc.ljh-cloud9-vpc.id
  peer_vpc_id = module.vpc.vpc_id
  auto_accept = true

  tags = {
    Name = "ljh-VPC-Peering"
  }
}

# Update route table of the Cloud9 instance subnet to add route to the new VPC
resource "aws_route" "route_to_new_vpc" {
  route_table_id            = data.aws_route_table.cloud9_subnet_route_table.id
  destination_cidr_block    = local.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

# Get the main route table of the new VPC
data "aws_route_table" "new_vpc_main_route_table" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

# Update route table of the new VPC to add route to the existing VPC
resource "aws_route" "route_to_ljh-cloud9-vpc" {
  route_table_id            = data.aws_route_table.new_vpc_main_route_table.id
  destination_cidr_block    = data.aws_vpc.ljh-cloud9-vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}