resource "vultr_instance" "addc" {
  label     = "${var.stack_name}-${var.addc_hostname}"
  hostname  = var.addc_hostname
  tag       = var.stack_name
  region    = var.stack_region
  plan      = var.server_plan
  os_id     = var.windows_os_id
  script_id = vultr_startup_script.init_windows.id

  private_network_ids    = [vultr_private_network.sp_vpn.id]
  enable_private_network = true
  activation_email       = false

  # no dependencies

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = var.admin_password
    host     = self.main_ip
    timeout  = "15m"
  }

  # Wait for instance setup
  provisioner "local-exec" {
    command = "sleep 120"
  }

  # Copy scripts and settings to instance
  provisioner "file" {
    content     = "vultr"
    destination = "C:\\setup\\provider.txt"
  }

  provisioner "file" {
    content     = var.admin_password
    destination = "C:\\setup\\pass.txt"
  }

  provisioner "file" {
    content     = var.domain_name
    destination = "C:\\setup\\domain.txt"
  }

  # Retry this step as terraform sometimes skips files
  provisioner "file" {
    source      = "../setup/addc/"
    destination = "C:\\setup"
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }

  provisioner "file" {
    source      = "../setup/addc/"
    destination = "C:\\setup"
  }

  # Configure IP addresses
  provisioner "file" {
    content     = local.addc_localip
    destination = "C:\\setup\\ip_addc.txt"
  }

  # Prepare networking
  provisioner "remote-exec" {
    inline = ["C:\\setup\\addc1-hostname.bat"]
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  # Setup Active Directory
  provisioner "remote-exec" {
    inline = ["C:\\setup\\addc2-init.bat"]
  }

  provisioner "local-exec" {
    command = "sleep 120" # delay for DC to warm up
  }

  # Configure AD Users
  provisioner "remote-exec" {
    inline = ["C:\\setup\\addc3-users.bat"]
  }
}

output "addc_public_ip" {
  value = vultr_instance.addc.main_ip
}
