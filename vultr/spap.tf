resource "vultr_instance" "spap" {
  label     = "${var.stack_name}-${var.spap_hostname}"
  hostname  = var.spap_hostname
  tag       = var.stack_name
  region    = var.stack_region
  plan      = var.server_plan
  os_id     = var.windows_os_id
  script_id = vultr_startup_script.init_windows.id

  private_network_ids    = [vultr_private_network.sp_vpn.id]
  enable_private_network = true
  activation_email       = false

  depends_on = [vultr_instance.addc, vultr_instance.msql]

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = var.admin_password
    host     = self.main_ip
    timeout  = "10m"
  }

  # Wait for instance setup
  provisioner "local-exec" {
    command = "sleep 90"
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

  provisioner "file" {
    source      = "../setup/spap/"
    destination = "C:\\setup"
  }

  provisioner "file" {
    content     = local.addc_localip
    destination = "C:\\setup\\ip_addc.txt"
  }

  provisioner "file" {
    content     = local.msql_localip
    destination = "C:\\setup\\ip_msql.txt"
  }

  provisioner "file" {
    content     = local.spap_localip
    destination = "C:\\setup\\ip_spap.txt"
  }

  provisioner "file" {
    content     = var.sharepoint_dir
    destination = "C:\\setup\\sp_dir.txt"
  }

  provisioner "file" {
    content     = local.sharepoint_config_xml
    destination = "C:\\setup\\sp_config.xml"
  }

  # Generalize Windows instance
  provisioner "file" {
    content     = local.sysprep_xml
    destination = "C:\\setup\\sysprep.xml"
  }

  provisioner "remote-exec" {
    inline = ["C:\\setup\\generalize.bat"]
  }

  provisioner "local-exec" {
    command = "sleep 90"
  }

  # Setup Sharepoint
  provisioner "remote-exec" {
    inline = ["C:\\setup\\spap1-hostname.bat"]
  }
}

output "spap_public_ip" {
  value = vultr_instance.spap.main_ip
}
