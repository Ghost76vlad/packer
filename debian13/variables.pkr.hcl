
# Proxmox
# ==============================
locals {
  proxmox_api_url = "https://${vault("/proxmox/data/api", "api_host")}/api2/json"
  proxmox_node    = vault("/proxmox/data/api", "node")
  user_uz         = vault("/infra/data/UZ", "user_ansible")
}

local "proxmox_api_token_secret" {
  expression = vault("/proxmox/data/api", "api_token_proxmox")
  sensitive  = true
}

local "proxmox_api_token_id" {
  expression = "${vault("/proxmox/data/api", "api_user")}!${vault("/proxmox/data/api", "api_token_id")}"
  sensitive  = true
}

local "user_pass" {
  expression = vault("/infra/data/UZ", "passwd_ansible")
  sensitive  = true # скроет значение в выводе/логах
}

# # Other
# # ==============================
# variable "user_uz" {
#   type    = string
#   default = "ansible"
# }
# variable "user_pass" {
#   type    = string
#   default = vault("/infra/data/uz", "passwd_ansible")
# } 
# # ==============================


