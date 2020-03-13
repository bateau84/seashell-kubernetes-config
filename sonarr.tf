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
                    fs_group = var.volume_fsgroup
                }

                node_selector = {
                    "kubernetes.io/hostname" = "morespace"
                }

                container {
                    name = "sonarr"
                    image = "linuxserver/sonarr:latest"
                    image_pull_policy = "Always"
                    
                    dynamic "volume_mount" {
                        for_each = var.sonarr_volume_mounts
                        content {
                            name = volume_mount.value.name
                            mount_path = volume_mount.value.mount_path
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
                        name = "sonarr"
                        container_port = var.sonarr_listen_port
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
                    for_each = var.sonarr_volume_mounts

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
        port        = var.sonarr_listen_port
        target_port = var.sonarr_listen_port
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
            service_port = var.sonarr_listen_port
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