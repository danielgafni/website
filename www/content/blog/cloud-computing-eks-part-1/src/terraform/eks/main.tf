data "aws_region" "current" {}

locals {
  cluster_name = var.cluster_name
  cluster_subdomain = "k8s-${data.aws_region.current.name}-${var.cluster_name}"
  tags = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # map with IAM users/roles and Kubernetes access permissions
  access_entries = var.access_entries

  create_iam_role = true
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  cluster_addons = {
    coredns = {
      most_recent = true  # TODO: pin exact version
    }
    kube-proxy = {
      most_recent = true  # TODO: pin exact version
      before_compute = true
    }
    vpc-cni = {
      most_recent = true  # TODO: pin exact version
      before_compute = true
    }

    aws-ebs-csi-driver = {
      most_recent = true  # TODO: pin exact version
    }

    amazon-cloudwatch-observability = {  # TODO: pin exact version
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size     = 2
      max_size     = 10
      desired_size = 2
    }
  }

  # https://stackoverflow.com/questions/74687452/eks-error-syncing-load-balancer-failed-to-ensure-load-balancer-multiple-tagge
  node_security_group_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = null
  }

  tags = merge(
    local.tags,
    {
      "karpenter.sh/discovery" = local.cluster_name
    }
  )
}