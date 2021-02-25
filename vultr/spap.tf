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
    content     = var.dropbox_url
    destination = "C:\\setup\\dropbox_url.txt"
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
    command = "sleep 60"
  }

  # Prepare networking
  provisioner "remote-exec" {
    inline = ["C:\\setup\\spap1-hostname.bat"]
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  # Join AD Domain
  provisioner "remote-exec" {
    inline     = ["C:\\setup\\spap2-join1.bat"]
    on_failure = continue # the join commandlet reboots instantly
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  provisioner "remote-exec" {
    inline     = ["C:\\setup\\spap2-join2.bat"]
    on_failure = continue # the join commandlet reboots instantly
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  # Download prerequisites and prepare Sharepoint Admin user
  provisioner "remote-exec" {
    inline = ["C:\\setup\\spap3-download.bat"]
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  # Install Windows Features
  provisioner "remote-exec" {
    inline = ["C:\\setup\\spap4-features.bat"]
  }

  provisioner "local-exec" {
    command = "sleep 120"
  }

  # Install Prerequisites
  provisioner "remote-exec" {
    inline = ["C:\\setup\\spap5-prereq.bat"]
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "null_resource" "spap_install" {
  # This step is separate because install sporadically fails with error 1603
  depends_on = [vultr_instance.spap, vultr_instance.msql]

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = var.admin_password
    host     = vultr_instance.spap.main_ip
    timeout  = "20m"
  }

  # Install Sharepoint
  provisioner "remote-exec" {
    inline     = ["C:\\setup\\spap6-install.bat"]
    on_failure = continue
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  # Retry the install (mitigate sporadic error 1603)
  provisioner "remote-exec" {
    inline = ["C:\\setup\\spap6-install.bat"]
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  # Patch Sharepoint
  provisioner "remote-exec" {
    inline = ["C:\\setup\\spap6-patch.bat"]
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "null_resource" "spap_apps" {
  # This step is separate because New-SPConfigurationDatabase sporadically fails
  depends_on = [vultr_instance.spap, vultr_instance.msql, null_resource.spap_install]

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = var.admin_password
    host     = vultr_instance.spap.main_ip
    timeout  = "30m"
  }

  # Create Farm
  provisioner "remote-exec" {
    inline = ["C:\\setup\\spap7-farm.bat"]
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  # Configure Applicatsions
  provisioner "remote-exec" {
    inline = ["C:\\setup\\spap8-apps.bat"]
  }

  # Reboot computer
  provisioner "remote-exec" {
    inline     = ["shutdown.exe /r"]
    on_failure = continue
  }
}

output "spap_public_ip" {
  value = vultr_instance.spap.main_ip
}

output "web_ip" {
  value = local.spap_localip
}

output "web_url" {
  value = "http://spap.${var.domain_name}/sites/test/Shared%20Documents"
}

output "web_user" {
  value = "${replace(var.domain_name, "/[.].*/", "")}\\spadmin"
}
