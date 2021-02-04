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

  depends_on = [aws_instance.addc, aws_instance.msql]

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = var.admin_password
    host     = self.public_ip
    timeout  = "15m"
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

  # Setup Sharepoint
  provisioner "remote-exec" {
    inline = ["C:\\setup\\spap1-hostname.bat"]
  }

  # Wait for completion
  provisioner "local-exec" {
    command = "sleep 3900"
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

output "spap_public_ip" {
  value = aws_instance.spap.public_ip
}
