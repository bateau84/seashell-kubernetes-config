variable "kube_config" {
  type = string
}

variable "base_dns_name" {
  type = string
}

variable "auth_secret_name" {
  type = string
}

variable "auth_lpass_id" {
  type = string
}

variable "namespace" {
    description = "Namespace to create nzbget, transmission, radarr and so on deployments in"
    type        = string
}

variable "deployments" {
    type = list(
      object(
        {
          name = string
          ports = list(
            object(
              {
                name = string
                port = string
                ingress = bool
                target_port = string
                protocol = string
              }
            )
          )
          annotations = any
          node_selector = object(
            {
              key = string
              value = string
            }
          )
          security_context = any
          image = string
          image_pull_policy = string
          readiness_probe = object(
            {
              initial_delay_seconds = string
              period_seconds = string
            }
          )
          liveness_probe = object(
            {
              initial_delay_seconds = string
              period_seconds = string
            }
          )
          volumes = list(
            object(
              {
                name = string
                mount_path = string
                path = string
              }
            )
          )
          envs = list(
            object(
              {
                name = string
                value = string
              }
            )
          )
        }
      )
    )
}

variable "certmanager_version" {
    type = string
}

variable "certmanager_deployment_args" {
    type = list(string)
    default = ["--v=2", "--leader-election-namespace=$(POD_NAMESPACE)",]
}

variable "certmanager_letsencrypt_email" {
  type = string
}

variable "certmanager_cainjactor_resource_requests" {
  type = map

  description = <<EOF
Resource Requests
ref http://kubernetes.io/docs/user-guide/compute-resources/
resource_requests = {
  memory = "256Mi"
  cpu = "100m"
}
EOF
  default = {}
}

variable "certmanager_cainjactor_resource_limits" {
  type = map

  description = <<EOF
Resource Requests
ref http://kubernetes.io/docs/user-guide/compute-resources/
resource_limits = {
  memory = "256Mi"
  cpu = "100m"
}
EOF
  default = {}
}

variable "certmanager_resource_requests" {
  type = map

  description = <<EOF
Resource Requests
ref http://kubernetes.io/docs/user-guide/compute-resources/
resource_requests = {
  memory = "256Mi"
  cpu = "100m"
}
EOF
  default = {}
}

variable "certmanager_resource_limits" {
  type = map

  description = <<EOF
Resource Requests
ref http://kubernetes.io/docs/user-guide/compute-resources/
resource_limits = {
  memory = "256Mi"
  cpu = "100m"
}
EOF
  default = {}
}

variable "certmanager_webhook_resource_requests" {
  type = map

  description = <<EOF
Resource Requests
ref http://kubernetes.io/docs/user-guide/compute-resources/
resource_requests = {
  memory = "256Mi"
  cpu = "100m"
}
EOF
  default = {}
}

variable "certmanager_webhook_resource_limits" {
  type = map

  description = <<EOF
Resource Requests
ref http://kubernetes.io/docs/user-guide/compute-resources/
resource_limits = {
  memory = "256Mi"
  cpu = "100m"
}
EOF
  default = {}
}