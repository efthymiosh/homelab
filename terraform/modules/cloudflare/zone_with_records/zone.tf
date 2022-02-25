resource "cloudflare_zone" "zone" {
  zone = var.zone
  type = var.zone_type
  plan = var.plan
}

resource "cloudflare_record" "rec" {
  for_each = { for r in var.records: "${r.name}_${r.value}" => r }

  zone_id = cloudflare_zone.zone.id

  name     = each.value.name
  type     = each.value.type
  value    = each.value.data == null ? each.value.value : null
  ttl      = each.value.ttl
  priority = each.value.priority

  dynamic "data" {
    for_each = each.value.data != null ? [ each.value.data ] : []
    content {
      service  = data.value.service
      proto    = data.value.proto
      name     = data.value.name
      priority = data.value.priority
      weight   = data.value.weight
      port     = data.value.port
      target   = each.value.value
    }
  }
}
