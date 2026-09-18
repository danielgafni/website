resource "helm_release" "traefik" {
  namespace        = "traefik"
  create_namespace = true
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = "27.0.2"
  wait             = true

  depends_on = [module.eks]

  values = [<<-YAML
    ingressClass:
      enabled: true
      isDefaultClass: true
      fallbackApiVersion: v1
    ingressRoute:
      dashboard:
        enabled: false
    service:
      name: traefik
      annotations:
        # create an external AWS LoadBalancer for this service
        service.beta.kubernetes.io/aws-load-balancer-type: nlb
    globalArguments:
      - "--api.insecure=true"
    YAML
  ]
}

data "kubernetes_service" "traefik" {
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }
  depends_on = [helm_release.traefik]
}

# route subdomain.domain to the AWS LoadBalancer (just in case)
resource "aws_route53_record" "traefik" {
  zone_id = var.zone_id
  name    = local.cluster_subdomain
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_service.traefik.status.0.load_balancer.0.ingress.0.hostname]
}

# route all web requests such as x.subdomain.domain to the AWS LoadBalanacer
resource "aws_route53_record" "traefik-wildcard" {
  zone_id = var.zone_id
  name    = "*.${local.cluster_subdomain}"
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_service.traefik.status.0.load_balancer.0.ingress.0.hostname]
}
