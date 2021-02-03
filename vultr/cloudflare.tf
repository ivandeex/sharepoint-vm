locals {
  record_count = var.domain_name != "example.com" ? 1 : 0
}

data "cloudflare_zones" "domain" {
  filter {
    name   = var.domain_name
    status = "active"
  }
}

resource "cloudflare_record" "addc" {
  count   = local.record_count
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "${var.stack_name}-${var.addc_hostname}"
  value   = vultr_instance.addc.main_ip
  type    = "A"
  ttl     = 60
  proxied = false
}

resource "cloudflare_record" "msql" {
  count   = local.record_count
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "${var.stack_name}-${var.msql_hostname}"
  value   = vultr_instance.msql.main_ip
  type    = "A"
  ttl     = 60
  proxied = false
}

resource "cloudflare_record" "spap" {
  count   = local.record_count
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "${var.stack_name}-${var.spap_hostname}"
  value   = vultr_instance.spap.main_ip
  type    = "A"
  ttl     = 60
  proxied = false
}

resource "cloudflare_record" "unix" {
  count   = local.record_count
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "${var.stack_name}-${var.unix_hostname}"
  value   = vultr_instance.unix.main_ip
  type    = "A"
  ttl     = 60
  proxied = false
}
