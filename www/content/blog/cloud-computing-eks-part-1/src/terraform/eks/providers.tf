provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster_auth" "default" {
  name = module.eks.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.default.token
  }
}

terraform {
    required_providers {
        kubectl = {
            source  = "alekc/kubectl"
            version = ">= 1.7.0"
        }
    }
}

# used mostly to apply CRs with CRDs
provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.default.token
  load_config_file = false
}

# can do more stuff than kubectl but can't apply CRs together with CRDs
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.default.token
}
