resource "aws_instance" "spap" {
  tags          = { Name = var.spap_hostname }
  ami           = lookup(var.aws_w2012r2_std_amis, var.aws_region)
  instance_type = var.aws_instance_type
  key_name      = lookup(var.ssh_key_name, var.aws_region)
  user_data     = local.aws_user_data

  subnet_id  = aws_subnet.default.id
  private_ip = local.spap_localip

  vpc_security_group_ids = [aws_security_group.sp_stack.id]

  # Additional disk for Sharepoint data
  ebs_block_device {
    device_name           = "/dev/xvdf"
    volume_size           = 10
    volume_type           = "standard"
    delete_on_termination = true
  }

  # Do not depend on MSQL yet, start earlier
  depends_on = [aws_instance.addc]

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = var.admin_password
    host     = self.public_ip
    timeout  = "30m"
  }

  # Wait for instance setup
  provisioner "local-exec" {
    command = "sleep 90"
  }

  # Copy scripts and settings to instance
  provisioner "file" {
    content     = "aws"
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

  # Retry this step as terraform sometimes skips files
  provisioner "file" {
    source      = "../setup/spap/"
    destination = "C:\\setup"
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }

  provisioner "file" {
    source      = "../setup/spap/"
    destination = "C:\\setup"
  }

  # Configure IP addresses
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
    command = "sleep 180"
  }

  # Install Prerequisites
  provisioner "remote-exec" {
    inline     = ["C:\\setup\\spap5-prereq.bat"]
    on_failure = continue # retry failures
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  provisioner "remote-exec" { # try again
    inline = ["C:\\setup\\spap5-prereq.bat"]
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "null_resource" "spap_install" {
  # This step is separate because install sporadically fails with error 1603
  # MSQL isn't used yet
  depends_on = [aws_instance.spap]

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = var.admin_password
    host     = aws_instance.spap.public_ip
    timeout  = "30m"
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
  # Also, it requires MSQL
  depends_on = [aws_instance.spap, aws_instance.msql, null_resource.spap_install]

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = var.admin_password
    host     = aws_instance.spap.public_ip
    timeout  = "50m"
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
  value = aws_instance.spap.public_ip
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
