resource "kubernetes_deployment" "deployment" {
    for_each = { for o in var.deployments : o.name => o }
    metadata {
        name = each.key
        namespace = kubernetes_namespace.namespace.metadata[0].name
    }

    spec {
        replicas = 1
        selector {
            match_labels = {
                app = each.key
            }
        }

        template {
            metadata {
                labels = {
                    app = each.key
                }
            }

            spec {
                security_context {
                    run_as_user = length(lookup(each.value.security_context, "run_as_user", "")) > 0 ? each.value.security_context.run_as_user : null
                    run_as_group = length(lookup(each.value.security_context, "run_as_group", "")) > 0 ? each.value.security_context.run_as_group : null
                    fs_group = length(lookup(each.value.security_context, "fs_group", "")) > 0 ? each.value.security_context.fs_group : null
                }

                node_selector = {
                    (each.value.node_selector.key) = each.value.node_selector.value
                }

                container {
                    name = each.key
                    image = each.value.image
                    image_pull_policy = each.value.image_pull_policy
                    
                    dynamic "volume_mount" {
                        for_each = each.value.volumes
                        content {
                            name = volume_mount.value.name
                            mount_path = volume_mount.value.mount_path
                        }
                    }

                    dynamic "env" {
                        for_each = each.value.envs
                        content {
                            name = env.value.name
                            value = env.value.value
                        }
                    }

                    dynamic "port" {
                        for_each = each.value.ports
                        content {
                            name = port.value.name
                            container_port = port.value.target_port
                        }
                    }

                    readiness_probe {
                        tcp_socket {
                            port = each.key
                        }
                        initial_delay_seconds = each.value.readiness_probe.initial_delay_seconds
                        period_seconds = each.value.readiness_probe.period_seconds
                    }

                    liveness_probe {
                        tcp_socket {
                            port = each.key
                        }
                        initial_delay_seconds = each.value.liveness_probe.initial_delay_seconds
                        period_seconds = each.value.liveness_probe.period_seconds
                    }
                }

                dynamic "volume" {
                    for_each = each.value.volumes
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

resource "kubernetes_service" "service" {
    for_each = { for o in var.deployments : o.name => o }
    metadata {
        name = each.key
        namespace = kubernetes_namespace.namespace.metadata[0].name
        labels = {
            app = each.key
        }
    }
    spec {
        selector = {
        app = each.key
        }
        dynamic "port" {
            for_each = each.value.ports
            content {
                name        = port.value.name
                port        = port.value.port
                target_port = port.value.target_port
                protocol    = port.value.protocol
            }
        }
        session_affinity = "None"
        type             = "ClusterIP"
    }
}

resource "kubernetes_ingress" "ingress" {
    for_each = { for o in var.deployments : o.name => o }
    lifecycle {
        ignore_changes = [spec[0].tls[0].secret_name]
    }
    metadata {
        name        = each.key
        namespace   = kubernetes_namespace.namespace.metadata[0].name
        annotations = each.value.annotations
    }

  spec {
    rule {
      host = "${each.key}.${var.base_dns_name}"
      http {
        path {
          dynamic "backend" {
              for_each = { for p in each.value.ports: p.name => p if p.ingress == true }
              content {
                service_name = backend.key
                service_port = backend.value.port
              }
          }
          path = "/"
        }
      }
    }
    tls {
      hosts = [ "${each.key}.${var.base_dns_name}" ]
    }
  }
}