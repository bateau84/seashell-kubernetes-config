apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-godaddy
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${mail}
    privateKeySecretRef:
      name: letsencrypt-godaddy
    solvers:
    - selector:
        dnsNames:
        - '${dns}'
      dns01:
        webhook:
          config:
            authApiKey: ${godaddy_api_key}
            authApiSecret: ${godaddy_api_secret}
            production: true
            ttl: 600
          groupName: ${group_name}
          solverName: godaddy