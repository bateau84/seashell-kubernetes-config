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
                    
                    volume_mount {
                        name = "config"
                        mount_path = "/config"
                    }
                    volume_mount {
                        name = "transcode"
                        mount_path = "/transcode"
                    }
                    volume_mount {
                        name = "downloads"
                        mount_path = "/downloads"
                    }
                    volume_mount {
                        name = "disk1"
                        mount_path = "/library/disk1"
                    }
                    volume_mount {
                        name = "disk2"
                        mount_path = "/library/disk2"
                    }
                    volume_mount {
                        name = "disk3"
                        mount_path = "/library/disk3"
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

                volume {
                    name = "config"
                    host_path {
                        path = "/home/bateau/opt/sonarr"
                    }
                }
                volume {
                    name = "transcode"
                    host_path {
                        path = "/media/ssd/plex/transcode"
                    }
                }
                volume {
                    name = "downloads"
                    host_path {
                        path = "/data/disk1/downloads"
                    }
                }
                volume {
                    name = "disk1"
                    host_path {
                        path = "/data/disk1/library"
                    }
                }
                volume {
                    name = "disk2"
                    host_path {
                        path = "/data/disk2/library"
                    }
                }
                volume {
                    name = "disk3"
                    host_path {
                        path = "/data/disk3/library"
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
            "certmanager.k8s.io/acme-challenge-type" = "http01"
            "certmanager.k8s.io/acme-http01-edit-in-place" = "false"
            "certmanager.k8s.io/cluster-issuer" = "letsencrypt"
            "nginx.ingress.kubernetes.io/auth-type" = "basic"
            "nginx.ingress.kubernetes.io/auth-secret" = "seashell-auth"
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