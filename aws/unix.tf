resource "aws_instance" "unix" {
  tags          = { Name = var.unix_hostname }
  ami           = lookup(var.aws_unix_amis, var.aws_region)
  instance_type = var.aws_unix_instance_type
  key_name      = lookup(var.ssh_key_name, var.aws_region)

  user_data = local.unix_init_script

  subnet_id  = aws_subnet.default.id
  private_ip = local.unix_localip

  vpc_security_group_ids = [aws_security_group.sp_stack.id]

  depends_on = [aws_instance.addc]

  connection {
    type        = "ssh"
    host        = self.public_ip
    port        = 22
    user        = "root"
    private_key = local.unix_private_key
  }

  # Wait for instance setup
  provisioner "local-exec" {
    command = "sleep 60"
  }

  # Upload settings and run setup
  provisioner "file" {
    content     = local.unix_defaults
    destination = "/etc/default/sharepoint"
  }

  provisioner "file" {
    source      = "../unix/setup.sh"
    destination = "/root/setup.sh"
  }

  provisioner "remote-exec" {
    inline = ["bash /root/setup.sh 2>&1 | tee /var/log/setup.log"]
  }
}

output "unix_public_ip" {
  value = aws_instance.unix.public_ip
}

locals {
  unix_init_script = templatefile("../unix/bootstrap.sh", {
    public_key = local.unix_public_key
  })
  unix_defaults = templatefile("../unix/defaults.sh", {
    unix_ethernet2 = local.unix_ethernet2,
    unix_localip   = local.unix_localip,
    addc_localip   = local.addc_localip,
    admin_password = var.admin_password,
    provider_name  = "aws"
  })
  unix_private_key = file("../unix/vagrant.key")
  unix_public_key  = file("../unix/vagrant.pub")
  unix_ethernet2   = ""
}
