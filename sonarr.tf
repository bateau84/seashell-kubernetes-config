resource "kubernetes_deployment" "sonarr" {
    metadata {
        name = "sonarr"
        namespace = kubernetes_namespace.namespace.metadata[0].name
    }

    spec {
        replicas = 1
        selector {
            match_labels = {
                app = "sonarr"
            }
        }

        template {
            metadata {
                labels = {
                    app = "sonarr"
                }
            }

            spec {
                security_context {
                    fs_group = local.sonarr_merged.fsgroup
                }

                node_selector = {
                    "kubernetes.io/hostname" = local.sonarr_merged.node_selector
                }

                container {
                    name = "sonarr"
                    image = local.sonarr_merged.image
                    image_pull_policy = "Always"
                    
                    dynamic "volume_mount" {
                        for_each = local.sonarr_merged.volumes
                        content {
                            name = volume_mount.value.name
                            mount_path = volume_mount.value.mount_path
                        }
                    }
                    
                    dynamic "env" {
                        for_each = local.sonarr_merged.envs
                        content {
                            name = env.value.name
                            value = env.value.value
                        }
                    }

                    port {
                        name = "sonarr"
                        container_port = local.sonarr_merged.port
                    }

                    readiness_probe {
                        tcp_socket {
                            port = "sonarr"
                        }
                        initial_delay_seconds = "120"
                        period_seconds = "5"
                    }

                    liveness_probe {
                        tcp_socket {
                            port = "sonarr"
                        }
                        initial_delay_seconds = "120"
                        period_seconds = "5"
                    }
                }

                dynamic "volume" {
                    for_each = local.sonarr_merged.volumes

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

resource "kubernetes_service" "sonarr" {
  metadata {
    name = "sonarr"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels = {
        app = "sonarr"
    }
  }
  spec {
    selector = {
      app = "sonarr"
    }
    port {
        name        = "sonarr"
        port        = local.sonarr_merged.port
        target_port = local.sonarr_merged.port
        protocol    = "TCP"
    }
    session_affinity = "None"
    type             = "ClusterIP"
  }
}

resource "kubernetes_ingress" "sonarr" {
    lifecycle {
        ignore_changes = [spec[0].tls[0].secret_name]
    }
    metadata {
        name        = "sonarr"
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
      host = "sonarr.${var.base_dns_name}"
      http {
        path {
          backend {
            service_name = "sonarr"
            service_port = local.sonarr_merged.port
          }
          path = "/"
        }
      }
    }
    tls {
      hosts = [ "sonarr.${var.base_dns_name}" ]
    }
  }
}