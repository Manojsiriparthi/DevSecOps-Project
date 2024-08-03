module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "example-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = module.vpc.public_subnets
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_cni_policy
  ]
}

resource "aws_eks_node_group" "example_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "example-node-group"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy,
    aws_iam_role_policy_attachment.eks_node_cni_policy,
    aws_iam_role_policy_attachment.eks_node_ec2_policy
  ]
}

data "aws_availability_zones" "available" {}
