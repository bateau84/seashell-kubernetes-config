resource "kubernetes_service_account" "godaddy-webhook" {
  metadata {
    name      = "godaddy-webhook"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "godaddy-webhook"
      "app.kubernetes.io/name" = "godaddy-webhook"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
}

resource "kubernetes_cluster_role" "godaddy-webhook_domain-solver" {
  metadata {
    name = "godaddy-webhook:domain-solver"
    labels = {
      "app" = "godaddy-webhook"
      "app.kubernetes.io/name" = "godaddy-webhook"
      "app.kubernetes.io/instance" = "cert-manager"
      "godaddy/group" = "${var.godaddy_group_name}"
    }
  }

  rule {
    api_groups = [var.godaddy_group_name]
    resources  = ["*"]
    verbs      = ["create"]
  }

  depends_on = [kubernetes_api_service.godaddy-webhook]
}

resource "kubernetes_cluster_role_binding" "godaddy-webhook_auth-delegator" {
  metadata {
    name = "godaddy-webhook:auth-delegator"
    labels = {
      "app" = "godaddy-webhook"
      "app.kubernetes.io/name" = "godaddy-webhook"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    name      = kubernetes_service_account.godaddy-webhook.metadata[0].name
  }
}

resource "kubernetes_cluster_role_binding" "godaddy-webhook_domain-solver" {
  metadata {
    name = "godaddy-webhook:domain-solver"
    labels = {
      "app" = "godaddy-webhook"
      "app.kubernetes.io/name" = "godaddy-webhook"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.godaddy-webhook_domain-solver.metadata[0].name
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    name      = kubernetes_service_account.godaddy-webhook.metadata[0].name
  }
}

resource "kubernetes_role_binding" "godaddy-webhook_webhook-authentication-reader" {
  metadata {
    name = "godaddy-webhook:webhook-authentication-reader"
    namespace = "kube-system"
    labels = {
      "app" = "godaddy-webhook"
      "app.kubernetes.io/name" = "godaddy-webhook"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "extension-apiserver-authentication-reader"
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    name      = kubernetes_service_account.godaddy-webhook.metadata[0].name
  }
}

resource "kubernetes_service" "godaddy-webhook" {
  metadata {
    name      = "godaddy-webhook"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "godday-webhook"
      "app.kubernetes.io/name" = "godday-webhook"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  spec {
    type = "ClusterIP"

    port {
      name        = "https"
      protocol    = "TCP"
      port        = 443
      target_port = "https"
    }

    selector = {
      "app" = "godday-webhook"
      "app.kubernetes.io/name" = "godday-webhook"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
}

resource "kubernetes_deployment" "godaddy-webhook" {
  metadata {
    name      = "godaddy-webhook"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "godday-webhook"
      "app.kubernetes.io/name" = "godday-webhook"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  depends_on = [null_resource.godaddy-ca]

  spec {
    replicas = "1"

    selector {
      match_labels = {
        "app" = "godday-webhook"
        "app.kubernetes.io/name" = "godday-webhook"
        "app.kubernetes.io/instance" = "cert-manager"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "godday-webhook"
          "app.kubernetes.io/name" = "godday-webhook"
          "app.kubernetes.io/instance" = "cert-manager"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.godaddy-webhook.metadata[0].name

        container {
          name              = "godaddy-webhook"
          image             = "inspectorio/cert-manager-webhook-godaddy:${var.godaddy_webhook_version}"
          image_pull_policy = "Always"

          args = [
            "--tls-cert-file=/certs/tls.crt",
            "--tls-private-key-file=/certs/tls.key"
          ]

          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          env {
            name = "GROUP_NAME"
            value = var.godaddy_group_name
          }

          resources {
            requests  {
              cpu = local.godaddy_webhook_actual_resource_requests["cpu"]
              memory = local.godaddy_webhook_actual_resource_requests["memory"]
            }

            limits {
              cpu = local.godaddy_webhook_actual_resource_limits["cpu"]
              memory = local.godaddy_webhook_actual_resource_limits["memory"]
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "https"
              scheme = "HTTPS"
            }
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = "https"
              scheme = "HTTPS"
            }
          }

          port {
            name = "https"
            container_port = 443
            protocol = "TCP"
          }

          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = "service-account"
            read_only  = true
          }

          volume_mount {
            mount_path = "/certs"
            name       = "certs"
            read_only  = true
          }
        }

        volume {
          name = "service-account"
          secret {
            secret_name = kubernetes_service_account.godaddy-webhook.default_secret_name
          }
        }

        volume {
          name = "certs"
          secret {
            secret_name = "godaddy-webhook-webhook-tls"
          }
        }
      }
    }
  }
}

resource "kubernetes_api_service" "godaddy-webhook" {
  metadata {
    name = "v1alpha2.${var.godaddy_group_name}"
    labels = {
      "app" = "godday-webhook"
      "app.kubernetes.io/name" = "godday-webhook"
      "app.kubernetes.io/instance" = "cert-manager"
      "godaddy/group" = "${var.godaddy_group_name}"
    }
    annotations = {
        "certmanager.k8s.io/inject-ca-from" = "${kubernetes_namespace.cert-manager.metadata[0].name}/godaddy-webhook-webhook-tls"
    }
  }

  spec {
    group = var.godaddy_group_name
    group_priority_minimum = 1000
    version_priority = 15

    service {
      name = kubernetes_service.godaddy-webhook.metadata[0].name
      namespace = kubernetes_namespace.cert-manager.metadata[0].name
    }

    version = "v1alpha2"
  }
}

resource "null_resource" "godaddy-ca" {
  triggers = {
    config = sha256(file("${path.module}/godaddy/godaddy.yaml"))
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/godaddy/godaddy.yaml"
    environment = {
      KUBECONFIG        = var.kube_config
    }
  }
}

data "template_file" "godaddy-clusterissuer-letsencrypt" {
  template = file(
    "${path.module}/godaddy/godaddy-clusterissuer-letsencrypt.yaml.tpl",
  )

  vars = {
    mail                = var.certmanager_letsencrypt_email
    dns                 = var.godaddy_dns
    godaddy_api_key     = data.lastpass_secret.godaddy.username
    godaddy_api_secret  = data.lastpass_secret.godaddy.password
    group_name          = var.godaddy_group_name
  }
}

resource "null_resource" "godaddy-clusterissuer-letsencrypt" {
  triggers = {
    deployment_id = kubernetes_service_account.godaddy-webhook.id
    template      = sha256(data.template_file.godaddy-clusterissuer-letsencrypt.rendered)
  }

  depends_on = [null_resource.godaddy-ca]

  provisioner "local-exec" {
    command = "${path.module}/kubectl-wrapper.sh"
    environment = {
      KUBECONFIG        = var.kube_config
      RESOURCE_DATA     = data.template_file.godaddy-clusterissuer-letsencrypt.rendered
    }
  }
}

data "template_file" "godaddy-certificate" {
  template = file(
    "${path.module}/godaddy/certificate.yaml.tpl",
  )

  vars = {
    name = replace(trim(var.godaddy_dns, "*"), ".", "-")
    dns  = var.godaddy_dns
  }
}

resource "null_resource" "godaddy-certificate" {
  triggers = {
    deployment_id = kubernetes_service_account.godaddy-webhook.id
    template      = sha256(data.template_file.godaddy-certificate.rendered)
  }

  depends_on = [null_resource.godaddy-clusterissuer-letsencrypt]

  provisioner "local-exec" {
    command = "${path.module}/kubectl-wrapper.sh"
    environment = {
      KUBECONFIG        = var.kube_config
      RESOURCE_DATA     = data.template_file.godaddy-certificate.rendered
    }
  }
}