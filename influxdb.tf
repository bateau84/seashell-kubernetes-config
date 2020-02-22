resource "kubernetes_deployment" "influxdb" {
    metadata {
        name = "influxdb"
        namespace = kubernetes_namespace.namespace.metadata[0].name
        labels = {
            app = "influxdb"
        }
    }

    spec {
        replicas = 1
        selector {
            match_labels = {
                app = "influxdb"
            }
        }

        template {
            metadata {
                labels = {
                    app = "influxdb"
                }
            }

            spec {
                node_selector = {
                    "kubernetes.io/hostname" = "morespace"
                }
                container {
                    name = "influxdb"
                    image = "docker.io/influxdb:1.7"
                    image_pull_policy = "Always"
                    
                    volume_mount {
                        name = "data"
                        mount_path = "/var/lib/influxdb"
                    }
                    volume_mount {
                        name = "config"
                        mount_path = "/etc/influxdb"
                    }
                }

                volume {
                    name = "data"
                    host_path {
                        path = "/home/bateau/opt/influxdb/data"
                    }
                }
                volume {
                    name = "config"
                    host_path {
                        path = "/home/bateau/opt/influxdb/config"
                    }
                }
            }
        }
    }
}

resource "kubernetes_service" "influxdb" {
  metadata {
    name = "influxdb"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels = {
        app = "influxdb"
    }
  }
  spec {
    selector = {
      app = "influxdb"
    }
    port {
        name        = "api"
        port        = "8086"
        target_port = "8086"
        protocol    = "TCP"
    }
    port {
        name        = "admin"
        port        = "8083"
        target_port = "8083"
        protocol    = "TCP"
    }
    port {
        name        = "graphite"
        port        = "2003"
        target_port = "2003"
        protocol    = "TCP"
    }

    session_affinity = "None"
    type             = "ClusterIP"
  }
}

resource "kubernetes_ingress" "influxdb" {
    lifecycle {
        ignore_changes = [spec[0].tls[0].secret_name]
    }
    metadata {
        name        = "influxdb"
        namespace   = kubernetes_namespace.namespace.metadata[0].name
        annotations = {
            "certmanager.k8s.io/acme-challenge-type" = "http01"
            "certmanager.k8s.io/acme-http01-edit-in-place" = "false"
            "certmanager.k8s.io/cluster-issuer" = "letsencrypt"
        }
    }

  spec {
    rule {
      host = "influxdb.${var.base_dns_name}"
      http {
        path {
          backend {
            service_name = "influxdb"
            service_port = "8086"
          }
          path = "/"
        }
      }
    }
    tls {
      hosts = [ "influxdb.${var.base_dns_name}" ]
    }
  }
}