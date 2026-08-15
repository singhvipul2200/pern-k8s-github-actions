# Uses the community-maintained terraform-aws-modules/eks module — the
# standard, well-tested way to build EKS clusters. This does NOT create a
# new VPC; it attaches to your existing VPC + public subnets.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Required so you can run kubectl from your own laptop, not just from
  # inside the VPC.
  cluster_endpoint_public_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids

  # NOTE: nodes are being placed in PUBLIC subnets here, matching what you
  # already have. This is fine for a learning/dev cluster. A production
  # setup would normally put worker nodes in private subnets behind a NAT
  # gateway instead, keeping only the load balancer public-facing.

  cluster_addons = {
    vpc-cni = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    pern_nodes = {
      instance_types = [var.node_instance_type]

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Spot pricing — significantly cheaper than on-demand, acceptable
      # trade-off (small risk of node reclaim) for a dev/learning cluster.
      capacity_type = "SPOT"

      subnet_ids = var.public_subnet_ids
    }
  }

  # Enables IAM Roles for Service Accounts — needed later if you add the
  # AWS Load Balancer Controller for Ingress.
  enable_irsa = true

  tags = {
    Project = "pern-store"
    Env     = "dev"
  }
}