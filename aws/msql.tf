resource "aws_instance" "msql" {
  tags          = { Name = var.msql_hostname }
  ami           = lookup(var.aws_w2012r2_mssql2014_amis, var.aws_region)
  instance_type = var.aws_instance_type
  key_name      = lookup(var.ssh_key_name, var.aws_region)
  user_data     = local.aws_user_data

  subnet_id  = aws_subnet.default.id
  private_ip = local.msql_localip

  vpc_security_group_ids = [aws_security_group.sp_stack.id]

  depends_on = [aws_instance.addc]

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = var.admin_password
    host     = self.public_ip
    timeout  = "15m"
  }

  # Wait for instance setup (longer than usual due to SQL Server setup)
  provisioner "local-exec" {
    command = "sleep 390"
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
    source      = "../setup/msql/"
    destination = "C:\\setup"
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }

  provisioner "file" {
    source      = "../setup/msql/"
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

  # Prepare networking
  provisioner "remote-exec" {
    inline = ["C:\\setup\\msql1-hostname.bat"]
  }

  provisioner "local-exec" {
    command = "sleep 90"
  }

  # Join AD Domain
  provisioner "remote-exec" {
    inline     = ["C:\\setup\\msql2-join1.bat"]
    on_failure = continue # the join commandlet reboots instantly
  }

  provisioner "local-exec" {
    command = "sleep 90"
  }

  provisioner "remote-exec" {
    inline     = ["C:\\setup\\msql2-join2.bat"]
    on_failure = continue # the join commandlet reboots instantly
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  # Install SQL Server
  provisioner "remote-exec" {
    inline = ["C:\\setup\\msql3-install.bat"]
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  # Configure SQL Server
  provisioner "remote-exec" {
    inline = ["C:\\setup\\msql4-init.bat"]
  }

  # Reboot computer
  provisioner "remote-exec" {
    inline     = ["shutdown.exe /r"]
    on_failure = continue
  }
}

output "msql_public_ip" {
  value = aws_instance.msql.public_ip
}
