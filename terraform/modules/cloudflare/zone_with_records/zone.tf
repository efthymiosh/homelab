resource "cloudflare_zone" "zone" {
  zone = var.zone
  type = var.zone_type
  plan = var.plan
}

resource "cloudflare_record" "rec" {
  for_each = { for r in var.records: "${r.name}_${r.value}" => r }

  zone_id = cloudflare_zone.zone.id

  name  = each.value.name
  type  = each.value.type
  value = each.value.value
  ttl   = each.value.ttl
}
