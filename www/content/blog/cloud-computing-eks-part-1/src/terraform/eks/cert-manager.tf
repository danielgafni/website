# this will create a role wich will be automatically assumed by 
# pods running in cert-manager namespace under cert-manager Kubernetes Service Account
module "eks-irsa-cert-manager" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "cert-manager-${local.cluster_subdomain}"

  attach_cert_manager_policy = true

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }
}


resource "helm_release" "cert-manager" {
  namespace           = "cert-manager"
  create_namespace    = true
  name                = "cert-manager"
  repository          = "https://charts.jetstack.io"
  chart               = "cert-manager"
  version = "1.14.5"
  wait                = true

  values = [ <<-YAML
    installCRDs: true

    serviceAccount:
      name: cert-manager  # make sure to pin the Service Account name for IRSA to work
      annotations:
        # specify the role to assume
        eks.amazonaws.com/role-arn: ${module.eks-irsa-cert-manager.iam_role_arn}

    # important for route53
    securityContext:
      fsGroup: 1001

    extraArgs:
    - --enable-certificate-owner-ref=true
    - --dns01-recursive-nameservers-only
    - --dns01-recursive-nameservers=8.8.8.8:53,1.1.1.1:53

    podDnsPolicy: "None"
    podDnsConfig:
      nameservers:
        - "1.1.1.1"
        - "8.8.8.8"

    YAML
  ]

    depends_on = [ module.eks ]
}


# create a ClusterIssuer for DNS-01 challange
resource "kubectl_manifest" "clusterIssuer-letsencrypt-prod-dns01" {
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
        name: letsencrypt-prod-dns01
        namespace: cert-manager
    spec:
        acme:
            email: "${var.acme_email}"
            server: "https://acme-v02.api.letsencrypt.org/directory"
            privateKeySecretRef:
                name: "letsencrypt-prod-dns01"  # Secret resource that will be used to store the account's private key.
            solvers:
            - dns01:
                route53:
                    region: ${var.route_53_region}
                    hostedZoneID: ${var.hosted_zone_id}
                selector:
                    dnsZones:
                        - '${local.cluster_subdomain}.${var.domain}'
                    dnsNames:
                        - '${local.cluster_subdomain}.${var.domain}'
                        - '*${local.cluster_subdomain}.${var.domain}'
    YAML

  depends_on = [
    helm_release.cert-manager
  ]
}
