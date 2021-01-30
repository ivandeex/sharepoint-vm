resource "vultr_private_network" "sp_vpn" {
  description    = "sharepoint private network"
  region         = var.stack_region
  v4_subnet      = "${var.private_net}.0"
  v4_subnet_mask = 24
}
