resource "vultr_instance" "msql" {
  label     = "${var.stack_name}-${var.msql_hostname}"
  hostname  = var.msql_hostname
  tag       = var.stack_name
  region    = var.stack_region
  plan      = var.server_plan
  os_id     = var.windows_os_id
  script_id = vultr_startup_script.init_windows.id

  private_network_ids    = [vultr_private_network.sp_vpn.id]
  enable_private_network = true
  activation_email       = false

  depends_on = [vultr_instance.addc]

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

  provisioner "file" {
    source      = "../setup/msql/"
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

  # Setup SQL Server
  provisioner "remote-exec" {
    inline = ["C:\\setup\\msql1-hostname.bat"]
  }

  # Wait for completion
  provisioner "local-exec" {
    command = "sleep 360"
  }

  provisioner "remote-exec" {
    inline     = ["C:\\setup\\wait.bat"]
    on_failure = continue
  }

  provisioner "local-exec" {
    command = "sleep 120"
  }

  provisioner "remote-exec" {
    inline = ["C:\\setup\\wait.bat"]
  }
}

output "msql_public_ip" {
  value = vultr_instance.msql.main_ip
}
