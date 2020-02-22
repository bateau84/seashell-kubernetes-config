provider "kubernetes" {
    config_path = var.kube_config
    alias       = "seashell"

    version = "~> 1.9.0"
}

provider "template" {
  version = "~> 2.1"
}

provider "null" {
  version = "~> 2.1"
}

provider "lastpass" {
  username = ""
  password = ""

  version = "~> 0.4"
}