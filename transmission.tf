resource "kubernetes_deployment" "transmission" {
    metadata {
        name = "transmission"
        namespace = kubernetes_namespace.namespace.metadata[0].name
    }

    spec {
        replicas = 1
        selector {
            match_labels = {
                app = "transmission"
            }
        }

        template {
            metadata {
                labels = {
                    app = "transmission"
                }
            }

            spec {
                security_context {
                    fs_group = var.transmission.fsgroup
                }

                node_selector = {
                    "kubernetes.io/hostname" = var.transmission.node_selector
                }

                container {
                    name = "transmission"
                    image = var.transmission.image
                    image_pull_policy = "Always"
                    
                    dynamic "volume_mount" {
                        for_each = var.transmission.volumes
                        content {
                            name = volume_mount.value.name
                            mount_path = volume_mount.value.mount_path
                        }
                    }
                    
                    dynamic "env" {
                        for_each = var.transmission.envs
                        content {
                            name = env.value.name
                            value = env.value.value
                        }
                    }

                    port {
                        name = "web"
                        container_port = var.transmission.port
                    }
                    port {
                        name = "tcp"
                        container_port = var.transmission.peer_port
                    }
                }

                dynamic "volume" {
                    for_each = var.transmission.volumes

                    content {
                        name = volume.value.name
                        host_path {
                            path = volume.value.path
                        }
                    }
                }
            }
        }
    }
}

resource "kubernetes_service" "transmission" {
  metadata {
    name = "transmission"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels = {
        app = "transmission"
    }
  }
  spec {
    selector = {
      app = "transmission"
    }
    port {
        name        = "transmission"
        port        = var.transmission.port
        target_port = var.transmission.port
        protocol    = "TCP"
    }
    session_affinity = "None"
    type             = "ClusterIP"
  }
}

resource "kubernetes_service" "transmission-peer" {
  metadata {
    name = "transmission-peer"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels = {
        app = "transmission"
    }
  }
  spec {
    selector = {
      app = "transmission"
    }
    port {
        name        = "transmission-peer"
        port        = var.transmission.peer_port
        target_port = var.transmission.peer_port
        protocol    = "TCP"
    }
    type             = "NodePort"
  }
}

resource "kubernetes_ingress" "transmission" {
    lifecycle {
        ignore_changes = [spec[0].tls[0].secret_name]
    }
    metadata {
        name        = "transmission"
        namespace   = kubernetes_namespace.namespace.metadata[0].name
        annotations = {
            "cert-manager.io/acme-challenge-type" = "http01"
            "cert-manager.io/acme-http01-edit-in-place" = "false"
            "cert-manager.io/cluster-issuer" = "letsencrypt"
            "nginx.ingress.kubernetes.io/auth-type" = "basic"
            "nginx.ingress.kubernetes.io/auth-secret" = var.auth_secret_name
            "nginx.ingress.kubernetes.io/auth-realm" = "Authentication Required"
        }
    }

  spec {
    rule {
      host = "transmission.${var.base_dns_name}"
      http {
        path {
          backend {
            service_name = "transmission"
            service_port = var.transmission.port
          }
          path = "/"
        }
      }
    }
    tls {
      hosts = [ "transmission.${var.base_dns_name}" ]
    }
  }
}