module "efthymios_me" {
  source = "./modules/cloudflare/zone_with_records"
  zone   = "efthymios.me"
  records = []
}

module "efhd_me" {
  source = "./modules/cloudflare/zone_with_records"
  zone   = "efhd.me"
  records = []
}

module "efth_eu" {
  source = "./modules/cloudflare/zone_with_records"
  zone   = "efth.eu"
  records = [
    { name = "snu1.int.efth.eu", type = "A", value = "192.168.1.240", ttl = 86400 },
    { name = "snu2.int.efth.eu", type = "A", value = "192.168.1.241", ttl = 86400 },
    { name = "snu3.int.efth.eu", type = "A", value = "192.168.1.242", ttl = 86400 },
  ]
}

module "efthymios_net" {
  source = "./modules/cloudflare/zone_with_records"
  zone   = "efthymios.net"

  records = [
    { name = "*.efthymios.net", type = "A", value = "192.168.1.240", ttl = 86400 },
    { name = "*.efthymios.net", type = "A", value = "192.168.1.241", ttl = 86400 },
    { name = "*.efthymios.net", type = "A", value = "192.168.1.242", ttl = 86400 },
  ]
}
