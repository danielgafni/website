# SSL certificate for Traefik's Dashboard UI
resource "kubectl_manifest" "certificate-traefik-dashboard" {
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: traefik-dashboard-${kubectl_manifest.clusterIssuer-letsencrypt-prod-dns01.name}
      namespace: traefik
    spec:
      secretName: traefik-dashboard-tls-${kubectl_manifest.clusterIssuer-letsencrypt-prod-dns01.name}
      dnsNames:
        - "traefik.${local.cluster_subdomain}.${var.domain}"
      issuerRef:
        kind: ClusterIssuer
        name: ${kubectl_manifest.clusterIssuer-letsencrypt-prod-dns01.name}
    YAML

}

# password for the dashboard's Basic Auth
resource "random_password" "traefik-dashboard" {
  length           = 16
  override_special = "<+)"
}

resource "aws_secretsmanager_secret" "traefik-dashboard" {
  name        = "traefik-dashboard-${local.cluster_subdomain}"
  description = "Traefik Dashboard credentials for https://traefik.${local.cluster_subdomain}.${var.domain}/dashboard/"
  tags        = local.tags
}

# store the password as ASM secret
resource "aws_secretsmanager_secret_version" "traefik-dashboard" {
  secret_id = aws_secretsmanager_secret.traefik-dashboard.id
  secret_string = jsonencode({
    user     = "admin",
    password = random_password.traefik-dashboard.result
  })
}

# store the dashboard password inside Kubernetes
resource "kubectl_manifest" "secret-traefik-dashboard-basic-auth-creds" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: traefik-dashboard-basic-auth-creds
      namespace: traefik
    type: kubernetes.io/basic-auth
    stringData:
      username: admin
      password: ${random_password.traefik-dashboard.result}
    YAML

  depends_on = [
    helm_release.traefik
  ]
}


# create a middleware for dashboard's Basic Auth
resource "kubectl_manifest" "middleware-traefik-dashboard-basic-auth" {
  yaml_body = <<-YAML
    apiVersion: traefik.containo.us/v1alpha1
    kind: Middleware
    metadata:
      name: traefik-dashboard-auth
      namespace: traefik
    spec:
      basicAuth:
        secret: ${kubectl_manifest.secret-traefik-dashboard-basic-auth-creds.name}
    YAML
}


# create a middleware to redirect HTTP requests to HTTPS
resource "kubectl_manifest" "middleware-https-redirectscheme" {
  yaml_body = <<-YAML
    apiVersion: traefik.containo.us/v1alpha1
    kind: Middleware
    metadata:
      name: https-redirectscheme
      namespace: traefik
    spec:
      redirectScheme:
        permanent: true
        scheme: https
    YAML
}


# create a route for Traefik
# this route will send all requests starting by traefik.subdomain.domain/dashboard/ 
# to the Traefik Dashboard Kubernetes service
# and insert the above middlewares into the route
resource "kubectl_manifest" "ingressRoute-traefik-dashboard" {
  yaml_body = <<-YAML
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: traefik-dashboard
      namespace: traefik
    spec:
      entryPoints:
        - web
        - websecure
      routes:
        - match: Host(`traefik.${local.cluster_subdomain}.${var.domain}`) && (PathPrefix(`/dashboard`, `/dashboard/`) || PathPrefix(`/api`, `/api/`))
          kind: Rule
          services:
            - name: api@internal
              kind: TraefikService
          middlewares:
            - name: ${kubectl_manifest.middleware-https-redirectscheme.name}
            - name: ${kubectl_manifest.middleware-traefik-dashboard-basic-auth.name}
      tls:
        secretName: traefik-dashboard-tls-${kubectl_manifest.clusterIssuer-letsencrypt-prod-dns01.name}
    YAML
}
