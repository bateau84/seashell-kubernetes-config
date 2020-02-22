apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: ingress-wildcard
  namespace: ingress-nginx
  labels:
    use-dns-solver: "true"
spec:
  secretName: default-ssl-certificate
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
  commonName: '*.${dns_zone_name}'
  dnsNames:
    - '*.${dns_zone_name}'