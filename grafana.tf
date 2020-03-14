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
                    "kubernetes.io/hostname" = var.grafana.node_selector
                }

                container {
                    name = "grafana"
                    image = var.grafana.image
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
                    
                    dynamic "volume_mount" {
                        for_each = var.grafana.volumes
                        content {
                            name = volume_mount.value.name
                            mount_path = volume_mount.value.mount_path
                        }
                    }
                    
                    dynamic "env" {
                        for_each = var.grafana.envs
                        content {
                            name = env.value.name
                            value = env.value.value
                        }
                    }

                    port {
                        name = "http"
                        container_port = var.grafana.port
                        protocol = "TCP"
                    }
                }

                dynamic "volume" {
                    for_each = var.grafana.volumes

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
        port        = var.grafana.port
        target_port = var.grafana.port
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
            "cert-manager.io/acme-challenge-type" = "http01"
            "cert-manager.io/acme-http01-edit-in-place" = "false"
            "cert-manager.io/cluster-issuer" = "letsencrypt"
        }
    }

  spec {
    rule {
      host = "grafana.${var.base_dns_name}"
      http {
        path {
          backend {
            service_name = "grafana"
            service_port = var.grafana.port
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