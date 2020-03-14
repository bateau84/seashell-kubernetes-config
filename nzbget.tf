resource "kubernetes_deployment" "nzbget" {
    metadata {
        name = "nzbget"
        namespace = kubernetes_namespace.namespace.metadata[0].name
    }

    spec {
        replicas = 1
        selector {
            match_labels = {
                app = "nzbget"
            }
        }

        template {
            metadata {
                labels = {
                    app = "nzbget"
                }
            }

            spec {
                security_context {
                    fs_group = var.nzbget.fsgroup
                }

                node_selector = {
                    "kubernetes.io/hostname" = var.nzbget.node_selector
                }

                container {
                    name = "nzbget"
                    image = var.nzbget.image
                    image_pull_policy = "Always"
                    
                    dynamic "volume_mount" {
                        for_each = var.nzbget.volumes
                        content {
                            name = volume_mount.value.name
                            mount_path = volume_mount.value.mount_path
                        }
                    }
                    
                    dynamic "env" {
                        for_each = var.nzbget.envs
                        content {
                            name = env.value.name
                            value = env.value.value
                        }
                    }

                    port {
                        name = "nzbget"
                        container_port = var.nzbget.port
                    }
                }

                dynamic "volume" {
                    for_each = var.nzbget.volumes

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

resource "kubernetes_service" "nzbget" {
  metadata {
    name = "nzbget"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels = {
        app = "nzbget"
    }
  }
  spec {
    selector = {
      app = "nzbget"
    }
    port {
        name        = "nzbget"
        port        = var.nzbget.port
        target_port = var.nzbget.port
        protocol    = "TCP"
    }
    session_affinity = "None"
    type             = "ClusterIP"
  }
}

resource "kubernetes_ingress" "nzbget" {
    lifecycle {
        ignore_changes = [spec[0].tls[0].secret_name]
    }
    metadata {
        name        = "nzbget"
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
      host = "nzbget.${var.base_dns_name}"
      http {
        path {
          backend {
            service_name = "nzbget"
            service_port = var.nzbget.port
          }
          path = "/"
        }
      }
    }
    tls {
      hosts = [ "nzbget.${var.base_dns_name}" ]
    }
  }
}