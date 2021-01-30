resource "aws_instance" "addc" {
  tags          = { Name = var.addc_hostname }
  ami           = lookup(var.aws_w2012r2_std_amis, var.aws_region)
  instance_type = var.aws_instance_type
  key_name      = lookup(var.ssh_key_name, var.aws_region)
  user_data     = local.aws_user_data

  subnet_id  = aws_subnet.default.id
  private_ip = local.addc_localip

  vpc_security_group_ids = [aws_security_group.sp_stack.id]

  # no dependencies

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = var.admin_password
    host     = self.public_ip
    timeout  = "10m"
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
    source      = "../setup/addc/"
    destination = "C:\\setup"
  }

  provisioner "file" {
    content     = local.addc_localip
    destination = "C:\\setup\\ip_addc.txt"
  }

  # Setup Active Directory
  provisioner "remote-exec" {
    inline = ["C:\\setup\\addc1-hostname.bat"]
  }
}

output "addc_public_ip" {
  value = aws_instance.addc.public_ip
}
