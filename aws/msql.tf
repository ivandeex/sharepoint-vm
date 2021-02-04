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

  # Wait for instance setup
  provisioner "local-exec" {
    command = "sleep 180"
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

  # Setup SQL Server
  provisioner "remote-exec" {
    inline = ["C:\\setup\\msql1-hostname.bat"]
  }

  # Wait for completion
  provisioner "local-exec" {
    command = "sleep 180"
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
  value = aws_instance.msql.public_ip
}
