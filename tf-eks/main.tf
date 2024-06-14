terraform {
  required_version = "~> 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = ">= 4.57.0"
      version = ">= 5.40.0"
    }
  }

  # backend "s3" {
  #   bucket         = "ljh-test-tfstate"
  #   key            = "ljh-test.tfstate"
  #   region         = "ap-northeast-2"
  #   #profile        = "ljh-test"
  #   profile        = "default"
  #   dynamodb_table = "ljh-TerraformStateLock"
  # }
}

provider "aws" {
  region = local.region
  # shared_config_files=["~/.aws/config"] # Or $HOME/.aws/config
  # shared_credentials_files = ["~/.aws/credentials"] # Or $HOME/.aws/credentials
  #profile        = "ljh-test"
  # profile        = "default"
}

# Error handling with "The configmap "aws-auth" does not exist"
# https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2009
# data "aws_eks_cluster" "default" {
#   name = module.eks.cluster_name
# }

# 새 VPC의 모든 프라이빗 라우팅 테이블에 기존 VPC CIDR 경로 추가
resource "aws_route" "route_to_existing_vpc" {
  count                     = length(module.vpc.private_route_table_ids)
  route_table_id            = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block    = data.aws_vpc.ljh-cloud9-vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

data "aws_vpc" "ljh-cloud9-vpc" {
  id = "vpc-08d05df0cdbcab781"
}

# Data source to get the Cloud9 instance (replace with actual Cloud9 instance ID)
data "aws_instance" "cloud9_instance" {
  instance_id = "i-05081af096a074f57"
}

# Data source to get the subnet where the Cloud9 instance is located
data "aws_subnet" "cloud9_subnet" {
  id = data.aws_instance.cloud9_instance.subnet_id
}

# Data source to get the route table associated with the Cloud9 instance subnet
data "aws_route_table" "cloud9_subnet_route_table" {
  filter {
    name   = "association.subnet-id"
    values = [data.aws_subnet.cloud9_subnet.id]
  }
}

##

data "aws_iam_role" "ljh_cloud9_test_admin" {
  name = "ljh-cloud9-test-admin"
}

data "aws_eks_cluster_auth" "default" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.default.token

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  name            = "ljh-eks"
  cluster_version = "1.28"
  region          = var.region

  vpc_cidr = "10.10.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    env  = "test"
    owner = "ljh"
  }
}

resource "aws_iam_policy" "additional" {
  name = "${local.name}-additional"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
  
  tags = local.tags
}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "1.1.0"

  aliases               = ["eks/${local.name}"]
  description           = "${local.name} cluster encryption key"
  enable_default_policy = true
  key_owners            = [data.aws_caller_identity.current.arn]

  tags = local.tags
}
