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
                    fs_group = var.volume_fsgroup
                }

                node_selector = {
                    "kubernetes.io/hostname" = "morespace"
                }

                container {
                    name = "nzbget"
                    image = "linuxserver/nzbget:latest"
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
                        name = "nzbget"
                        container_port = var.nzbget_listen_port
                    }
                }

                volume {
                    name = "config"
                    host_path {
                        path = "/home/bateau/opt/nzbget"
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
        port        = var.nzbget_listen_port
        target_port = var.nzbget_listen_port
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
      host = "nzbget.${var.base_dns_name}"
      http {
        path {
          backend {
            service_name = "nzbget"
            service_port = var.nzbget_listen_port
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