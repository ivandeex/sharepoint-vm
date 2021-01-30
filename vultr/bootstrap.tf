resource "vultr_startup_script" "init_windows" {
  name   = "${var.stack_name}-init_windows"
  script = base64encode(local.windows_init_script)
}

locals {
  windows_init_script = templatefile("../templates/wininit.cmd", {
    admin_password = var.admin_password
  })
  sysprep_xml = templatefile("../templates/sysprep.xml", {
    admin_password = var.admin_password
  })
  sharepoint_config_xml = templatefile("../templates/sharepoint_config.xml", {
    sharepoint_dir = var.sharepoint_dir
    sep            = "\\"
  })
}
