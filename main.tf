resource "kubernetes_namespace" "namespace" {
    metadata {
        name = var.namespace
    }
}

resource "kubernetes_secret" "auth" {
    metadata {
        name = var.auth_secret_name
        namespace = kubernetes_namespace.namespace.metadata[0].name
    }

    data = { 
        auth = data.lastpass_secret.seashell-auth.note
    }

    type = "Opaque"
}

module "ingress-nginx" {
    source  = "git@github.com:bateau84/terraform-kubernetes-ingress-nginx"

    controller_version = "0.29.0"
    controller_replicas = 1
    namespace = "ingress-nginx"
    cloud_provider = "node_port"
    resource_limits = {
        memory = "512Mi"
        cpu = "500m"
    }
    resource_requests = {
        memory = "256Mi"
        cpu = "200m"
    }
}