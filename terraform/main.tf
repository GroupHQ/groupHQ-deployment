data "aws_availability_zones" "available" {}

locals {
  name = "grouphq-staging"
  vpc_cidr = "10.0.0.0/16"
  region   = "us-east-2"

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  intra_subnets    = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 3)]
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 6)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 9)]

  default_tags = {
    Terraform   = "true"
    Environment = "staging"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = local.vpc_cidr

  azs              = local.azs
  intra_subnets    = local.intra_subnets
  private_subnets  = local.private_subnets
  public_subnets   = local.public_subnets
  database_subnets = local.database_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.default_tags
}

module "fck-nat" {
  source = "github.com/RaJiska/terraform-aws-fck-nat?ref=9377bf9247c96318b99273eb2978d1afce8cf0eb"

  name      = "grouphq-staging-fck-nat"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]

  use_cloudwatch_agent = false

  update_route_tables = true
  route_tables_ids = {
    for index, route_table_id in module.vpc.private_route_table_ids : "routeTable${index}" => route_table_id
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name = local.name

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = concat(module.vpc.private_subnets, module.vpc.public_subnets)
  control_plane_subnet_ids = module.vpc.intra_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t4g.medium"]
  }

  eks_managed_node_groups = {
    karpenter = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["t4g.medium"]
      subnet_ids = module.vpc.private_subnets

      min_size     = 1
      max_size     = 1
      desired_size = 1
    }
  }

  enable_cluster_creator_admin_permissions = true

  access_entries = {
    admin = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::010438489417:role/GroupHQ_Staging_Admin"

      # See https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html for list of EKS access policies
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = local.default_tags
}