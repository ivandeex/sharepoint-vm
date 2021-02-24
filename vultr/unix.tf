resource "vultr_instance" "unix" {
  label     = "${var.stack_name}-${var.unix_hostname}"
  hostname  = var.unix_hostname
  tag       = var.stack_name
  region    = var.stack_region
  plan      = var.server_plan
  os_id     = var.unix_os_id
  script_id = vultr_startup_script.init_unix.id

  private_network_ids    = [vultr_private_network.sp_vpn.id]
  enable_private_network = true
  activation_email       = false

  depends_on = [vultr_instance.addc]

  connection {
    type        = "ssh"
    host        = self.main_ip
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
  value = vultr_instance.unix.main_ip
}

resource "vultr_startup_script" "init_unix" {
  name   = "${var.stack_name}-init_unix"
  script = base64encode(local.unix_init_script)
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
    provider_name  = "vultr"
  })
  unix_private_key = file("../unix/vagrant.key")
  unix_public_key  = file("../unix/vagrant.pub")
  unix_ethernet2   = "ens7"
}
