simple module for my stuff.

use it as follows:
```
module "seashell" {
    source  = "git@github.com:bateau84/seashell-config"

    kube_config                     = "/some/path/.kube/config"
    base_dns_name                   = "something.example.com"
    auth_secret_name                = "doom-auth"
    auth_lpass_id                   = ""
    namespace                       = "your-namespace-of-doom"
    deployments                     = [
        {
            name = "influxdb"
            ports = [
                {
                    name = "influxdb"
                    port = "8086"
                    ingress = true
                    target_port = "8086"
                    protocol = "TCP"
                },{
                    name = "admin"
                    port = "8083"
                    ingress = false
                    target_port = "8083"
                    protocol = "TCP"
                },{
                    name = "graphite"
                    port = "2003"
                    ingress = false
                    target_port = "2003"
                    protocol = "TCP"
                }
            ]
            annotations = {
                "cert-manager.io/cluster-issuer" = "letsencrypt",
            }
            node_selector = {
                key = "kubernetes.io/hostname"
                value = "some-server-of-doom"
            }
            fs_group = null
            run_as_group = null
            run_as_user = null
            image = "docker.io/influxdb:1.7"
            image_pull_policy = "Always"
            readiness_probe = {
                initial_delay_seconds = "15"
                period_seconds = "20"
            }
            liveness_probe = {
                initial_delay_seconds = "5"
                period_seconds = "10"
            }
            volumes = [
                {
                    name        = "data"
                    mount_path  = "/var/lib/influxdb"
                    path       = "/some/where/on/your/disk"
                },{
                    name        = "config"
                    mount_path  = "/etc/influxdb"
                    path       = "/some/where/on/your/other/disk"
                }
            ]
            envs = [
                {
                    name = "TZ"
                    value = "Europe/Oslo"
                }
            ]
        }
    certmanager_version             = "v0.13.1"
    certmanager_letsencrypt_email   = "some.email@company.com"
}
```