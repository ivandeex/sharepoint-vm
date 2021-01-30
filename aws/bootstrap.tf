locals {
  aws_user_data = templatefile("../templates/aws_userdata.xml", {
    admin_password = var.admin_password
  })
  sharepoint_config_xml = templatefile("../templates/sharepoint_config.xml", {
    sharepoint_dir = var.sharepoint_dir
    sep            = "\\"
  })
}
