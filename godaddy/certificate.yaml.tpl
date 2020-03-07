apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: wildcard${name}
spec:
  secretName: wildcard${name}
  renewBefore: 240h
  dnsNames:
  - '${dns}'
  issuerRef:
    name: letsencrypt-godaddy
    kind: ClusterIssuer