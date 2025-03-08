
resource "helm_release" "node-local-dns" {
  namespace  = "kube-system"
  name       = "node-local-dns"
  repository = "https://charts.deliveryhero.io"
  chart      = "node-local-dns"
  version    = "2.0.9"
  wait       = true
}
