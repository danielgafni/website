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
  YAML
}
