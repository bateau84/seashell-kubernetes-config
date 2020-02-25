resource "null_resource" "cert-manager-crd" {
  triggers = {
    config = sha256(file("${path.module}/certmanager/certmanager-crds.yaml"))
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/certmanager/certmanager-crds.yaml"
    environment = {
      KUBECONFIG        = var.kube_config
    }
  }
}

resource "null_resource" "cert-manager-webhookconfiguration" {
  triggers = {
    config = sha256(file("${path.module}/certmanager/webhook.yaml"))
  }

  depends_on = [null_resource.cert-manager-crd]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/certmanager/certmanager-crds.yaml"
    environment = {
      KUBECONFIG        = var.kube_config
    }
  }
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    labels = {
      "cert-manager.io/disable-validation" = "true"
      "app.kubernetes.io/name" : "cert-manager"
      "app.kubernetes.io/part-of" : "cert-manager"
    }
    name = "cert-manager"
  }

  depends_on = [null_resource.cert-manager-crd]
}

resource "kubernetes_service_account" "cert-manager-cainjector" {
  metadata {
    name      = "cert-manager-cainjector"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "cainjector"
      "app.kubernetes.io/name" = "cainjector"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
}

resource "kubernetes_service_account" "cert-manager" {
  metadata {
    name      = "cert-manager"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
}

resource "kubernetes_service_account" "cert-manager-webhook" {
  metadata {
    name      = "cert-manager-webhook"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "webhook"
      "app.kubernetes.io/name" = "webhook"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
}

resource "kubernetes_cluster_role" "cert-manager-cainjector" {
  metadata {
    name = "cert-manager-cainjector"
    labels = {
      "app" = "cainjector"
      "app.kubernetes.io/name" = "cainjector"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["certificates"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "create", "update", "patch"]
  }
  rule {
    api_groups = ["admissionregistration.k8s.io"]
    resources  = ["validatingwebhookconfigurations", "mutatingwebhookconfigurations"]
    verbs      = ["get", "list", "watch", "update"]
  }
  rule {
    api_groups = ["apiregistration.k8s.io"]
    resources  = ["apiservices"]
    verbs      = ["get", "list", "watch", "update"]
  }
  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["get", "list", "watch", "update"]
  }

  depends_on = [null_resource.cert-manager-crd]
}

resource "kubernetes_cluster_role_binding" "cert-manager-cainjector" {
  metadata {
    name = "cert-manager-cainjector"
    labels = {
      "app" = "cainjector"
      "app.kubernetes.io/name" = "cainjector"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cert-manager-cainjector.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    name      = kubernetes_service_account.cert-manager-cainjector.metadata[0].name
  }
}

resource "kubernetes_role" "cert-manager-cainjector_leaderelection" {
  metadata {
    name = "cert-manager-cainjector:leaderelection"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "cainjector"
      "app.kubernetes.io/name" = "cainjector"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "create", "update", "patch"]
  }
}

resource "kubernetes_role_binding" "cert-manager-cainjector_leaderelection" {
  metadata {
    name = "cert-manager-cainjector:leaderelection"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "cainjector"
      "app.kubernetes.io/name" = "cainjector"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      =  kubernetes_role.cert-manager-cainjector_leaderelection.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    name      = kubernetes_service_account.cert-manager-cainjector.metadata[0].name
  }
}

resource "kubernetes_role_binding" "cert-manager-webhook_auth-delegator" {
  metadata {
    name = "cert-manager-webhook:auth-delegator"
    labels = {
      "app" = "webhook"
      "app.kubernetes.io/name" = "webhook"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "extension-apiserver-authentication-reader"
  }

  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    name      = kubernetes_service_account.cert-manager-webhook.metadata[0].name
  }
}

resource "kubernetes_role_binding" "cert-manager-webhook_webhook-authentication-reader" {
  metadata {
    name = "cert-manager-webhook:webhook-authentication-reader"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "webhook"
      "app.kubernetes.io/name" = "webhook"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "extension-apiserver-authentication-reader"
  }

  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    name      = kubernetes_service_account.cert-manager.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "cert-manager-webhook_webhook-requester" {
  metadata {
    name = "cert-manager-webhook:webhook-requester"
    labels = {
      "app" = "webhook"
      "app.kubernetes.io/name" = "webhook"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  rule {
    api_groups = ["admission.cert-manager.io"]
    resources  = ["certificates", "certificaterequests", "issuers", "clusterissuers"]
    verbs      = ["create"]
  }
}

resource "kubernetes_role" "cert-manager_leaderelection" {
  metadata {
    name = "cert-manager:leaderelection"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "create", "update", "patch"]
  }
}

resource "kubernetes_role_binding" "cert-manager_leaderelection" {
  metadata {
    name = "cert-manager:leaderelection"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "cert-manager:leaderelection"
  }

  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    name      = kubernetes_service_account.cert-manager.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "cert-manager-controller-issuers" {
  metadata {
    name = "cert-manager-controller-issuers"
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["issuers", "issuers/status"]
    verbs      = ["update"]
  }
  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["issuers"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }

  depends_on = [null_resource.cert-manager-crd]
}

resource "kubernetes_cluster_role" "cert-manager-controller-clusterissuers" {
  metadata {
    name = "cert-manager-controller-clusterissuers"
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["clusterissuers", "clusterissuers/status"]
    verbs      = ["update"]
  }
  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["clusterissuers"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }

  depends_on = [null_resource.cert-manager-crd]
}

resource "kubernetes_cluster_role" "cert-manager-controller-certificates" {
  metadata {
    name = "cert-manager-controller-certificates"
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["certificates", "certificates/status", "certificaterequests", "certificaterequests/status"]
    verbs      = ["update"]
  }
  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["certificates", "certificaterequests", "clusterissuers", "issuers"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["certificates/finalizers", "certificaterequests/finalizers"]
    verbs      = ["update"]
  }
  rule {
    api_groups = ["acme.cert-manager.io"]
    resources  = ["orders"]
    verbs      = ["create", "delete", "get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }

  depends_on = [null_resource.cert-manager-crd]
}

resource "kubernetes_cluster_role" "cert-manager-controller-orders" {
  metadata {
    name = "cert-manager-controller-orders"
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  rule {
    api_groups = ["acme.cert-manager.io"]
    resources  = ["orders", "orders/status"]
    verbs      = ["update"]
  }
  rule {
    api_groups = ["acme.cert-manager.io"]
    resources  = ["orders", "challenges"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["clusterissuers", "issuers"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["acme.cert-manager.io"]
    resources  = ["challenges"]
    verbs      = ["create", "delete"]
  }
  rule {
    api_groups = ["acme.cert-manager.io"]
    resources  = ["orders/finalizers"]
    verbs      = ["update"]
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }

  depends_on = [null_resource.cert-manager-crd]
}

resource "kubernetes_cluster_role" "cert-manager-controller-challenges" {
  metadata {
    name = "cert-manager-controller-challenges"
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  rule {
    api_groups = ["acme.cert-manager.io"]
    resources  = ["challenges", "challenges/status"]
    verbs      = ["update"]
  }
  rule {
    api_groups = ["acme.cert-manager.io"]
    resources  = ["challenges"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["issuers", "clusterissuers"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["get", "list", "watch", "create", "delete"]
  }
  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch", "create", "delete", "update"]
  }
  rule {
    api_groups = ["acme.cert-manager.io"]
    resources  = ["challenges/finalizers"]
    verbs      = ["update"]
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [null_resource.cert-manager-crd]
}

resource "kubernetes_cluster_role" "cert-manager-controller-ingress-shim" {
  metadata {
    name = "cert-manager-controller-ingress-shim"
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["certificates", "certificaterequests"]
    verbs      = ["create", "update", "delete"]
  }
  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["certificates", "certificaterequests", "issuers", "clusterissuers"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses/finalizers"]
    verbs      = ["update"]
  }
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }

  depends_on = [null_resource.cert-manager-crd]
}

resource "kubernetes_cluster_role_binding" "cert-manager-controller-issuers" {
  metadata {
    name = "cert-manager-controller-issuers"
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cert-manager-controller-issuers.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    name      = kubernetes_service_account.cert-manager.metadata[0].name
  }
}

resource "kubernetes_cluster_role_binding" "cert-manager-controller-clusterissuers" {
  metadata {
    name = "cert-manager-controller-clusterissuers"
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cert-manager-controller-clusterissuers.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    name      = kubernetes_service_account.cert-manager.metadata[0].name
  }
}

resource "kubernetes_cluster_role_binding" "cert-manager-controller-certificates" {
  metadata {
    name = "cert-manager-controller-certificates"
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cert-manager-controller-certificates.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    name      = kubernetes_service_account.cert-manager.metadata[0].name
  }
}

resource "kubernetes_cluster_role_binding" "cert-manager-controller-orders" {
  metadata {
    name = "cert-manager-controller-orders"
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cert-manager-controller-orders.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    name      = kubernetes_service_account.cert-manager.metadata[0].name
  }
}

resource "kubernetes_cluster_role_binding" "cert-manager-controller-challenges" {
  metadata {
    name = "cert-manager-controller-challenges"
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cert-manager-controller-challenges.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    name      = kubernetes_service_account.cert-manager.metadata[0].name
  }
}

resource "kubernetes_cluster_role_binding" "cert-manager-controller-ingress-shim" {
  metadata {
    name = "cert-manager-controller-ingress-shim"
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cert-manager-controller-ingress-shim.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    name      = kubernetes_service_account.cert-manager.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "cert-manager-view" {
  metadata {
    name = "cert-manager-view"
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
      "rbac.authorization.k8s.io/aggregate-to-view" = "true"
      "rbac.authorization.k8s.io/aggregate-to-edit" = "true"
      "rbac.authorization.k8s.io/aggregate-to-admin" = "true"
    }
  }

  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["certificates", "certificaterequests", "issuers"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [null_resource.cert-manager-crd]
}

resource "kubernetes_cluster_role" "cert-manager-edit" {
  metadata {
    name = "cert-manager-edit"
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
      "rbac.authorization.k8s.io/aggregate-to-edit" = "true"
      "rbac.authorization.k8s.io/aggregate-to-admin" = "true"
    }
  }

  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["certificates", "certificaterequests", "issuers"]
    verbs      = ["create", "delete", "deletecollection", "patch", "update"]
  }

  depends_on = [null_resource.cert-manager-crd]
}

resource "kubernetes_service" "cert-manager" {
  metadata {
    name      = "cert-manager"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  spec {
    type = "ClusterIP"

    port {
      protocol    = "TCP"
      port        = 9402
      target_port = 9402
    }

    selector = {
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
}

resource "kubernetes_service" "cert-manager-webhook" {
  metadata {
    name      = "cert-manager-webhook"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "webhook"
      "app.kubernetes.io/name" = "webhook"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  spec {
    type = "ClusterIP"

    port {
      protocol    = "TCP"
      port        = 443
      target_port = 10250
    }

    selector = {
      "app" = "webhook"
      "app.kubernetes.io/name" = "webhook"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
}

resource "kubernetes_deployment" "cert-manager-cainjector" {
  metadata {
    name      = "cert-manager-cainjector"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "cainjector"
      "app.kubernetes.io/name" = "cainjector"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  spec {
    replicas = "1"

    selector {
      match_labels = {
        "app" = "cainjector"
        "app.kubernetes.io/name" = "cainjector"
        "app.kubernetes.io/instance" = "cert-manager"
      }
    }

    template {
      metadata {
        namespace = kubernetes_namespace.cert-manager.metadata[0].name
        labels = {
          "app" = "cainjector"
          "app.kubernetes.io/name" = "cainjector"
          "app.kubernetes.io/instance" = "cert-manager"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.cert-manager-cainjector.metadata[0].name

        container {
          name              = "cert-manager"
          image             = "quay.io/jetstack/cert-manager-cainjector:${var.certmanager_version}"
          image_pull_policy = "Always"

          args = var.certmanager_deployment_args

          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          resources {
            requests  {
              cpu = local.certmanager_cainjactor_actual_resource_requests["cpu"]
              memory = local.certmanager_cainjactor_actual_resource_requests["memory"]
            }

            limits {
              cpu = local.certmanager_cainjactor_actual_resource_limits["cpu"]
              memory = local.certmanager_cainjactor_actual_resource_limits["memory"]
            }
          }

          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = "service-account"
            read_only  = true
          }
        }

        volume {
          name = "service-account"
          secret {
            secret_name = kubernetes_service_account.cert-manager-cainjector.default_secret_name
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "cert-manager" {
  metadata {
    name      = "cert-manager"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "cert-manager"
      "app.kubernetes.io/name" = "cert-manager"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  spec {
    replicas = "1"

    selector {
      match_labels = {
        "app" = "cert-manager"
        "app.kubernetes.io/name" = "cert-manager"
        "app.kubernetes.io/instance" = "cert-manager"
      }
    }

    template {
      metadata {
        namespace = kubernetes_namespace.cert-manager.metadata[0].name
        labels = {
          "app" = "cert-manager"
          "app.kubernetes.io/name" = "cert-manager"
          "app.kubernetes.io/instance" = "cert-manager"
        }
        annotations = {
          "prometheus.io/path"    = "/metrics"
          "prometheus.io/scrape"  = "true"
          "prometheus.io/port"    = "9402"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.cert-manager.metadata[0].name

        container {
          name              = "cert-manager"
          image             = "quay.io/jetstack/cert-manager-controller:${var.certmanager_version}"
          image_pull_policy = "Always"

          args = [
            "--v=2",
            "--cluster-resource-namespace=$(POD_NAMESPACE)",
            "--leader-election-namespace=$(POD_NAMESPACE)",
            "--webhook-namespace=$(POD_NAMESPACE)",
            "--webhook-ca-secret=cert-manager-webhook-ca",
            "--webhook-serving-secret=cert-manager-webhook-tls",
            "--webhook-dns-names=cert-manager-webhook,cert-manager-webhook.cert-manager,cert-manager-webhook.cert-manager.svc"
          ]

          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          resources {
            requests  {
              cpu = local.certmanager_actual_resource_requests["cpu"]
              memory = local.certmanager_actual_resource_requests["memory"]
            }

            limits {
              cpu = local.certmanager_actual_resource_limits["cpu"]
              memory = local.certmanager_actual_resource_limits["memory"]
            }
          }

          port {
            container_port = 9402
            protocol = "TCP"
          }

          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = "service-account"
            read_only  = true
          }
        }

        volume {
          name = "service-account"
          secret {
            secret_name = kubernetes_service_account.cert-manager.default_secret_name
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "cert-manager-webhook" {
  metadata {
    name      = "cert-manager-webhook"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
    labels = {
      "app" = "webhook"
      "app.kubernetes.io/name" = "webhook"
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }

  spec {
    replicas = "1"

    selector {
      match_labels = {
        "app" = "webhook"
        "app.kubernetes.io/name" = "webhook"
        "app.kubernetes.io/instance" = "cert-manager"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "webhook"
          "app.kubernetes.io/name" = "webhook"
          "app.kubernetes.io/instance" = "cert-manager"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.cert-manager-webhook.metadata[0].name

        container {
          name              = "cert-manager"
          image             = "quay.io/jetstack/cert-manager-webhook:${var.certmanager_version}"
          image_pull_policy = "Always"

          args = [
            "--v=2",
            "--secure-port=10250",
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

          resources {
            requests  {
              cpu = local.certmanager_actual_resource_requests["cpu"]
              memory = local.certmanager_actual_resource_requests["memory"]
            }

            limits {
              cpu = local.certmanager_actual_resource_limits["cpu"]
              memory = local.certmanager_actual_resource_limits["memory"]
            }
          }

          liveness_probe {
            http_get {
              path = "/livez"
              port = "6080"
              scheme = "HTTP"
            }
          }

          readiness_probe {
            http_get {
              path = "/livez"
              port = "6080"
              scheme = "HTTP"
            }
          }

          port {
            container_port = 10250
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
            secret_name = kubernetes_service_account.cert-manager.default_secret_name
          }
        }

        volume {
          name = "certs"
          secret {
            secret_name = "cert-manager-webhook-tls"
          }
        }
      }
    }
  }
}

data "template_file" "clusterissuer-letsencrypt" {
  template = file(
    "${path.module}/certmanager/clusterissuer-letsencrypt.yaml.tpl",
  )

  vars = {
    mail         = var.certmanager_letsencrypt_email
  }
}

resource "null_resource" "clusterissuer-letsencrypt" {
  triggers = {
    deployment_id = kubernetes_service_account.cert-manager.id
    template      = data.template_file.clusterissuer-letsencrypt.rendered
  }

  depends_on = [null_resource.cert-manager-crd, kubernetes_deployment.cert-manager-webhook]

  provisioner "local-exec" {
    command = "${path.module}/kubectl-wrapper.sh"
    environment = {
      KUBECONFIG        = var.kube_config
      RESOURCE_DATA     = data.template_file.clusterissuer-letsencrypt.rendered
    }
  }
}
