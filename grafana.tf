resource "kubernetes_deployment" "grafana" {
    metadata {
        name = "grafana"
        namespace = kubernetes_namespace.namespace.metadata[0].name
        labels = {
            app = "grafana"
        }
    }

    spec {
        replicas = 1
        selector {
            match_labels = {
                app = "grafana"
            }
        }

        template {
            metadata {
                labels = {
                    app = "grafana"
                }
            }

            spec {
                security_context {
                    fs_group = 475
                    run_as_user = 475
                }

                node_selector = {
                    "kubernetes.io/hostname" = "morespace"
                }

                container {
                    name = "grafana"
                    image = "grafana/grafana:6.5.2"
                    image_pull_policy = "Always"

                    resources {
                        limits {
                            cpu = "100m"
                            memory = "100Mi"
                        }
                        requests {
                            cpu = "100m"
                            memory = "100Mi"
                        }
                    }
                    
                    volume_mount {
                        name = "grafana-config"
                        mount_path = "/etc/grafana/config.ini"
                    }
                    volume_mount {
                        name = "grafana-data-storage"
                        mount_path = "/var/lib/grafana"
                    }
                    
                    env {
                        name = "GF_AUTH_BASIC_ENABLED"
                        value = "false"
                    }
                    env {
                        name = "GF_AUTH_ANONYMOUS_ENABLED"
                        value = "true"
                    }
                    env {
                        name = "GF_AUTH_ANONYMOUS_ORG_ROLE"
                        value = "Admin"
                    }
                    env {
                        name = "GF_SERVER_ROOT_URL"
                        value = "%(protocol)s://%(domain)s:%(http_port)s/"
                    }

                    port {
                        name = "http"
                        container_port = "3000"
                        protocol = "TCP"
                    }
                }

                volume {
                    name = "grafana-config"
                    host_path {
                        path = "/home/bateau/opt/grafana/conf/grafana.ini"
                    }
                }
                volume {
                    name = "grafana-data-storage"
                    host_path {
                        path = "/home/bateau/opt/grafana/data"
                    }
                }
            }
        }
    }
}

resource "kubernetes_service" "grafana" {
  metadata {
    name = "grafana"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels = {
        app = "grafana"
    }
  }
  spec {
    selector = {
      app = "grafana"
    }
    port {
        name        = "grafana"
        port        = var.grafana_listen_port
        target_port = var.grafana_listen_port
        protocol    = "TCP"
    }
    session_affinity = "None"
    type             = "ClusterIP"
  }
}

resource "kubernetes_ingress" "grafana" {
    lifecycle {
        ignore_changes = [spec[0].tls[0].secret_name]
    }
    metadata {
        name        = "grafana"
        namespace   = kubernetes_namespace.namespace.metadata[0].name
        annotations = {
            "certmanager.k8s.io/acme-challenge-type" = "http01"
            "certmanager.k8s.io/acme-http01-edit-in-place" = "false"
            "certmanager.k8s.io/cluster-issuer" = "letsencrypt"
        }
    }

  spec {
    rule {
      host = "grafana.${var.base_dns_name}"
      http {
        path {
          backend {
            service_name = "grafana"
            service_port = var.grafana_listen_port
          }
          path = "/"
        }
      }
    }
    tls {
      hosts = [ "grafana.${var.base_dns_name}" ]
    }
  }
}