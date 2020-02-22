variable "kube_config" {
  type = string
}

variable "base_dns_name" {
  type = string
}

variable "namespace" {
    description = "Namespace to create nzbget, transmission, radarr and so on deployments in"
    type        = string
}

variable "volume_fsgroup" {
    type = number
}

variable "sonarr_nodeselector" {
    default = "morespace"
    type = string
}

variable "sonarr_listen_port" {
    default = "8989"
    type = string
}

variable "radarr_nodeselector" {
    default = "morespace"
    type = string
}

variable "radarr_listen_port" {
    default = "7878"
    type = string
}

variable "transmission_nodeselector" {
    default = "morespace"
    type = string
}

variable "transmission_listen_port" {
    default = "9091"
    type = string
}

variable "transmission_peer_port" {
    default = "31413"
    type = string
}

variable "nzbget_nodeselector" {
    default = "morespace"
    type = string
}

variable "nzbget_listen_port" {
    default = "6789"
    type = string
}

variable "grafana_listen_port" {
    default = "3000"
    type = string
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