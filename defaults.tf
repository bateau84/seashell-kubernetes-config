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

variable "default_grafana" {
  default = {
      port = "3000"
      fsgroup = "1000"
      image = "grafana/grafana:6.5.2"
      volumes = []
      envs = []
  }
  description = "Default Values (Do not set)"
}

variable "default_transmission" {
  default = {
      port = "9091"
      peer_port = "31413"
      fsgroup = "1000"
      image = "linuxserver/transmission:latest"
      volumes = []
      envs = []
  }
  description = "Default Values (Do not set)"
}

variable "default_nzbget" {
  default = {
      port = "6789"
      fsgroup = "1000"
      image = "linuxserver/nzbget:latest"
      volumes = []
      envs = []
  }
  description = "Default Values (Do not set)"
}

variable "default_sonarr" {
  default = {
      port = "8989"
      fsgroup = "1000"
      image = "linuxserver/sonarr:latest"
      volumes = []
      envs = []
  }
  description = "Default Values (Do not set)"
}

variable "default_radarr" {
  default = {
      port = "7878"
      fsgroup = "1000"
      image = "linuxserver/radarr:latest"
      volumes = []
      envs = []
  }
  description = "Default Values (Do not set)"
}