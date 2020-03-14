resource "kubernetes_deployment" "transmission" {
    metadata {
        name = "transmission"
        namespace = kubernetes_namespace.namespace.metadata[0].name
    }

    spec {
        replicas = 1
        selector {
            match_labels = {
                app = "transmission"
            }
        }

        template {
            metadata {
                labels = {
                    app = "transmission"
                }
            }

            spec {
                security_context {
                    fs_group = local.transmission_merged.fsgroup
                }

                node_selector = {
                    "kubernetes.io/hostname" = local.transmission_merged.node_selector
                }

                container {
                    name = "transmission"
                    image = local.transmission_merged.image
                    image_pull_policy = "Always"
                    
                    dynamic "volume_mount" {
                        for_each = local.transmission_merged.volumes
                        content {
                            name = volume_mount.value.name
                            mount_path = volume_mount.value.mount_path
                        }
                    }
                    
                    dynamic "env" {
                        for_each = local.transmission_merged.envs
                        content {
                            name = env.value.name
                            value = env.value.value
                        }
                    }

                    port {
                        name = "web"
                        container_port = local.transmission_merged.port
                    }
                    port {
                        name = "tcp"
                        container_port = local.transmission_merged.peer_port
                    }
                }

                dynamic "volume" {
                    for_each = local.transmission_merged.volumes

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

resource "kubernetes_service" "transmission" {
  metadata {
    name = "transmission"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels = {
        app = "transmission"
    }
  }
  spec {
    selector = {
      app = "transmission"
    }
    port {
        name        = "transmission"
        port        = local.transmission_merged.port
        target_port = local.transmission_merged.port
        protocol    = "TCP"
    }
    session_affinity = "None"
    type             = "ClusterIP"
  }
}

resource "kubernetes_service" "transmission-peer" {
  metadata {
    name = "transmission-peer"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels = {
        app = "transmission"
    }
  }
  spec {
    selector = {
      app = "transmission"
    }
    port {
        name        = "transmission-peer"
        port        = local.transmission_merged.peer_port
        target_port = local.transmission_merged.peer_port
        protocol    = "TCP"
    }
    type             = "NodePort"
  }
}

resource "kubernetes_ingress" "transmission" {
    lifecycle {
        ignore_changes = [spec[0].tls[0].secret_name]
    }
    metadata {
        name        = "transmission"
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
      host = "transmission.${var.base_dns_name}"
      http {
        path {
          backend {
            service_name = "transmission"
            service_port = local.transmission_merged.port
          }
          path = "/"
        }
      }
    }
    tls {
      hosts = [ "transmission.${var.base_dns_name}" ]
    }
  }
}