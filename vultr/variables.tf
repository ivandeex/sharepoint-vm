# provider settings
variable "stack_region" {
  # Frankfurt
  default = "fra"
}

variable "server_plan" {
  # curl -sL https://api.vultr.com/v2/plans | jq -C . | less
  default = "vc2-1c-2gb"
}

# vm images
variable "windows_os_id" {
  # Windows 2012 R2 x64
  default = 124
}

# server names
variable "stack_name" {
  default = "sptest"
}

variable "addc_hostname" {
  default = "addc"
}

variable "msql_hostname" {
  default = "msql"
}

variable "spap_hostname" {
  default = "spap"
}

# private network
variable "private_net" {
  default = "10.20.30"
}

locals {
  addc_localip = "${var.private_net}.5"
  msql_localip = "${var.private_net}.6"
  spap_localip = "${var.private_net}.7"
}

# application settings
variable "domain_name" {
  default = "example.com"
}

variable "sharepoint_dir" {
  default = "C:\\Sharepoint"
}

variable "admin_password" {
  default = "Summer.0"
  # sensitive values cause bugs in terraform
  #sensitive = true
}
