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
    volume_fsgroup                  = 1000
    sonar_nodeselector              = "server01"
    radarr_nodeselector             = "server01"
    transmission_nodeselector       = "server01"
    nzbget_nodeselector             = "server01"
    certmanager_version             = "v0.13.1"
    certmanager_letsencrypt_email   = "some.email@company.com"
}
```