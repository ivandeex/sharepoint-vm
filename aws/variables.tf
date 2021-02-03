# provider settings
variable "aws_region" {
  default = "eu-central-1"
}

variable "aws_instance_type" {
  default = "t2.medium"
}

variable "aws_unix_instance_type" {
  default = "t2.small"
}

variable "ssh_key_name" {
  default = {
    "us-east-1"    = "my_ssh_key"
    "us-west-2"    = "my_ssh_key"
    "eu-central-1" = "my_ssh_key"
  }
}

# vm images
variable "aws_w2012r2_std_amis" {
  # Windows_Server-2012-R2_RTM-English-64Bit-Base
  default = {
    us-east-1    = "ami-079fe16082fb837c5"
    us-west-2    = "ami-0d886083a2ac8d80c"
    eu-central-1 = "ami-03a092d4ec340dbbf"
  }
}

variable "aws_w2012r2_mssql2014_amis" {
  # Windows_Server-2012-R2_RTM-English-64Bit-SQL_2014_SP3_Express
  default = {
    us-east-1    = "ami-0b46a90270c75f4b0"
    us-west-2    = "ami-081eb1c95c801cbb9"
    eu-central-1 = "ami-0b430b012fdb0c907"
  }
}

variable "aws_unix_amis" {
  # Ubuntu 20.04 LTS x64
  default = {
    us-east-1    = "ami-03d315ad33b9d49c4"
    us-west-2    = "ami-0928f4202481dfdf6"
    eu-central-1 = "ami-0932440befd74cdba"
  }
}

# server names
variable "stack_name" {
  default = "sptest"
}

variable "addc_hostname" {
  default = "addc"
}

variable "msql_hostname" {
  default = "msql"
}

variable "spap_hostname" {
  default = "spap"
}

variable "unix_hostname" {
  default = "unix"
}

# private network
variable "private_net" {
  default = "10.20.30"
}

locals {
  addc_localip = "${var.private_net}.5"
  msql_localip = "${var.private_net}.6"
  spap_localip = "${var.private_net}.7"
  unix_localip = "${var.private_net}.8"
}

# application settings
variable "domain_name" {
  default = "example.com"
}

variable "sharepoint_dir" {
  default = "D:\\Sharepoint"
}

variable "admin_password" {
  default = "Summer.0"
  # sensitive values cause bugs in terraform
  #sensitive = true
}
