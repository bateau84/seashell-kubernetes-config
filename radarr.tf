resource "kubernetes_deployment" "radarr" {
    metadata {
        name = "radarr"
        namespace = kubernetes_namespace.namespace.metadata[0].name
    }

    spec {
        replicas = 1
        selector {
            match_labels = {
                app = "radarr"
            }
        }

        template {
            metadata {
                labels = {
                    app = "radarr"
                }
            }

            spec {
                security_context {
                    fs_group = local.radarr_merged.fsgroup
                }

                node_selector = {
                    "kubernetes.io/hostname" = local.radarr_merged.node_selector
                }

                container {
                    name = "radarr"
                    image = local.radarr_merged.image
                    image_pull_policy = "Always"
                    
                    dynamic "volume_mount" {
                        for_each = local.radarr_merged.volumes
                        content {
                            name = volume_mount.value.name
                            mount_path = volume_mount.value.mount_path
                        }
                    }

                    dynamic "env" {
                        for_each = local.radarr_merged.envs
                        content {
                            name = env.value.name
                            value = env.value.value
                        }
                    }

                    port {
                        name = "radarr"
                        container_port = local.radarr_merged.port
                    }

                    readiness_probe {
                        tcp_socket {
                            port = "radarr"
                        }
                        initial_delay_seconds = "15"
                        period_seconds = "20"
                    }

                    liveness_probe {
                        tcp_socket {
                            port = "radarr"
                        }
                        initial_delay_seconds = "5"
                        period_seconds = "10"
                    }
                }

                dynamic "volume" {
                    for_each = local.radarr_merged.volumes
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

resource "kubernetes_service" "radarr" {
  metadata {
    name = "radarr"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels = {
        app = "radarr"
    }
  }
  spec {
    selector = {
      app = "radarr"
    }
    port {
        name        = "radarr"
        port        = local.radarr_merged.port
        target_port = local.radarr_merged.port
        protocol    = "TCP"
    }
    session_affinity = "None"
    type             = "ClusterIP"
  }
}

resource "kubernetes_ingress" "radarr" {
    lifecycle {
        ignore_changes = [spec[0].tls[0].secret_name]
    }
    metadata {
        name        = "radarr"
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
      host = "radarr.${var.base_dns_name}"
      http {
        path {
          backend {
            service_name = "radarr"
            service_port = local.radarr_merged.port
          }
          path = "/"
        }
      }
    }
    tls {
      hosts = [ "radarr.${var.base_dns_name}" ]
    }
  }
}