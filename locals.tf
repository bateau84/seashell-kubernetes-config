variable "default_resource_requests" {
  default = {
    cpu = "100m"
    memory = "64M"
  }
  description = "Default Values (Do not set)"
}

variable "default_resource_limits"  {
  default = {
    cpu = "200m"
    memory = "128M"
  }
  description = "Default Values (Do not set)"
}

locals {
  certmanager_cainjactor_actual_resource_requests = merge(var.default_resource_requests, var.certmanager_cainjactor_resource_requests)
  certmanager_cainjactor_actual_resource_limits = merge(var.default_resource_limits, var.certmanager_cainjactor_resource_limits)
}

locals {
  certmanager_actual_resource_requests = merge(var.default_resource_requests, var.certmanager_resource_requests)
  certmanager_actual_resource_limits = merge(var.default_resource_limits, var.certmanager_resource_limits)
}

locals {
  certmanager_webhook_actual_resource_requests = merge(var.default_resource_requests, var.certmanager_webhook_resource_requests)
  certmanager_webhook_actual_resource_limits = merge(var.default_resource_limits, var.certmanager_webhook_resource_limits)
}
