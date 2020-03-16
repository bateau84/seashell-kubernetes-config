## TODO: get godaddy-webhook or something
/* data "lastpass_secret" "godaddy" {
  id = "8070072020439480664"
} */

data "lastpass_secret" "seashell-auth" {
  id = var.auth_lpass_id
}