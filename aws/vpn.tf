# VPC Creation
resource "aws_vpc" "sharepoint" {
  cidr_block           = "${var.private_net}.0/24"
  enable_dns_hostnames = true
}

# Create Subnet for all of our resources
resource "aws_subnet" "default" {
  vpc_id     = aws_vpc.sharepoint.id
  cidr_block = "${var.private_net}.0/24"
  tags       = { Name = var.stack_name }

  map_public_ip_on_launch = true
}

# IGW for external calls
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.sharepoint.id
  tags   = { Name = var.stack_name }
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.sharepoint.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Main Route Table
resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.sharepoint.id
  route_table_id = aws_route_table.main.id
}

# Provide a VPC DHCP Option Association
resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.sharepoint.id
  dhcp_options_id = aws_vpc_dhcp_options.dns_resolver.id
}

# Set DNS resolvers so we can join a Domain Controller
resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = [
    "8.8.8.8",
    "8.8.4.4",
    local.addc_localip
  ]
  tags = { Name = var.stack_name }
}

# Security Group Creation
resource "aws_security_group" "sp_stack" {
  name        = "sharepoint_sg"
  description = "Security Group for Sharepoint"
  vpc_id      = aws_vpc.sharepoint.id
  tags        = { Name = var.stack_name }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
