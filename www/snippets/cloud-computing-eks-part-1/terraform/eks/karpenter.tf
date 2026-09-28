# this module creates supporting infrastructure for Karpenter
# like IAM and spot instances info SQS queue
# but doesn't deploy Karpenter itself
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.8.5"

  cluster_name           = module.eks.cluster_name
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn

  # Used to attach additional IAM policies to the Karpenter node IAM role
  enable_irsa         = true # TODO: uncomment this
  enable_pod_identity = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}

# here we actually install Karpenter with helm
resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "0.36.0"
  wait             = true

  values = [
    <<-EOT
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    EOT
  ]
}

# add a default NodeClass
resource "kubectl_manifest" "karpenter-node-class-default" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
      namespace: karpenter
    spec:
      amiFamily: AL2
      role: ${module.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter # need to add this explicit dependency
  ]
}

# add a default NodePool
resource "kubectl_manifest" "karpenter-node-pool-default" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
      namespace: karpenter
    spec:
      template:
        spec:
          nodeClassRef:
            name: ${kubectl_manifest.karpenter-node-class-default.name}
          requirements:
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand"]
            - key: karpenter.k8s.aws/instance-category
              operator: In
              values: ["c", "m", "r", "t"]
      limits:
        cpu: 100
      disruption:
        consolidationPolicy: WhenUnderutilized
      expireAfter: 720h
  YAML
}

resource "kubectl_manifest" "karpenter-node-class-deeplearning" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: deeplearning
      namespace: karpenter
    spec:
      amiFamily: AL2
      amiSelectorTerms:
        - name: amazon-eks-gpu-node-${module.eks.cluster_version}-v20240703  # optimized gpu ami
      role: ${module.karpenter.node_iam_role_name}
      # increase static storage size to handle large DL images
      blockDeviceMappings:
      - deviceName: /dev/xvda
        ebs:
          volumeSize: ${var.volume_size_gb} # set to something like 100Gi
          volumeType: gp3
          iops: 10000
          deleteOnTermination: true
          throughput: 125
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}}
      disruption:
        consolidationPolicy: WhenUnderutilized
      expireAfter: 720h
  YAML
}
