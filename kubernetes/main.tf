terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.22.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "5.1.2"

    name = "otavio-vpc-01"
    cidr = "10.0.0.0/16"

    azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

    enable_nat_gateway = true  

    tags = {
        "kubernetes.io/cluster/otavio-eks" = "shared"
    }

    public_subnet_tags = {
        "kubernetes.io/cluster/otavio-eks" = "shared"
        "kubernetes.io/role/elb" = 1    
    }

    private_subnet_tags = {
        "kubernetes.io/cluster/otavio-eks" = "shared"
        "kubernetes.io/role/internal-elb" = 1    
    }  
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.17.2"

  cluster_name = "otavio-eks"
  cluster_version = "1.28"

  cluster_endpoint_public_access  = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets

    eks_managed_node_groups = {
        default = {
        min_size     = 1
        max_size     = 3
        desired_size = 3

        instance_types = ["t3.micro"]
        }
    }  

}
