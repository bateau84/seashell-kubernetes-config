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
                    fs_group = var.volume_fsgroup
                }

                node_selector = {
                    "kubernetes.io/hostname" = "morespace"
                }

                container {
                    name = "radarr"
                    image = "linuxserver/radarr:latest"
                    image_pull_policy = "Always"
                    
                    dynamic "volume_mount" {
                        for_each = to_set(var.radarr_volume_mounts)
                        content {
                            name = volume_mount.name
                            mount_path = volume_mount.mount_path
                        }
                    }
                    
                    env {
                        name = "PUID"
                        value = var.volume_fsgroup
                    }
                    env {
                        name = "PGID"
                        value = var.volume_fsgroup
                    }
                    env {
                        name = "TZ"
                        value = "Europe/Oslo"
                    }

                    port {
                        name = "radarr"
                        container_port = var.radarr_listen_port
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
                    for_each = to_set(var.radarr_volume_mounts)

                    content {
                        name = volume.name
                        host_path {
                            path = volume.path
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
        port        = var.radarr_listen_port
        target_port = var.radarr_listen_port
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
            service_port = var.radarr_listen_port
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