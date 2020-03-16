locals {
  // grafana_merged = merge(var.default_grafana, var.grafana)
  // transmission_merged = merge(var.default_transmission, var.transmission)
  // nzbget_merged = merge(var.default_nzbget, var.nzbget)
  // sonarr_merged = merge(var.default_sonarr, var.sonarr)
  // radarr_merged = merge(var.default_radarr, var.radarr)

  certmanager_cainjactor_actual_resource_requests = merge(var.default_resource_requests, var.certmanager_cainjactor_resource_requests)
  certmanager_cainjactor_actual_resource_limits = merge(var.default_resource_limits, var.certmanager_cainjactor_resource_limits)
  certmanager_actual_resource_requests = merge(var.default_resource_requests, var.certmanager_resource_requests)
  certmanager_actual_resource_limits = merge(var.default_resource_limits, var.certmanager_resource_limits)
  certmanager_webhook_actual_resource_requests = merge(var.default_resource_requests, var.certmanager_webhook_resource_requests)
  certmanager_webhook_actual_resource_limits = merge(var.default_resource_limits, var.certmanager_webhook_resource_limits)
}
