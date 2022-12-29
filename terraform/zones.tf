module "efthymios_net" {
  source = "./modules/cloudflare/zone_with_records"
  zone   = "efthymios.net"

  records = [
    { name = "*.efthymios.net", type = "A", value = "192.168.1.240", ttl = 86400 },
    { name = "*.efthymios.net", type = "A", value = "192.168.1.241", ttl = 86400 },
    { name = "*.efthymios.net", type = "A", value = "192.168.1.242", ttl = 86400 },
  ]
}

module "efthymios_me" {
  source = "./modules/cloudflare/zone_with_records"
  zone   = "efthymios.me"
  records = []
}

module "efhd_eu" {
  source = "./modules/cloudflare/zone_with_records"
  zone   = "efhd.eu"
  records = []
}

module "efhd_dev" {
  source = "./modules/cloudflare/zone_with_records"
  zone   = "efhd.dev"

  records = [
    { name = "*.efhd.dev", type = "A", value = "192.168.1.240", ttl = 86400 },
    { name = "*.efhd.dev", type = "A", value = "192.168.1.241", ttl = 86400 },
    { name = "*.efhd.dev", type = "A", value = "192.168.1.242", ttl = 86400 },

    { name = "snu1.int.efhd.dev", type = "A", value = "192.168.1.240", ttl = 86400 },
    { name = "snu2.int.efhd.dev", type = "A", value = "192.168.1.241", ttl = 86400 },
    { name = "snu3.int.efhd.dev", type = "A", value = "192.168.1.242", ttl = 86400 },
    { name = "mule.int.efhd.dev", type = "A", value = "192.168.1.82",  ttl = 300   },


    # migadu.com verification, e-mail servers
    { name = "efhd.dev", type = "TXT", value = "hosted-email-verify=fumx1lv8", ttl = 86400 },
    { name = "efhd.dev", type = "MX",  value = "aspmx1.migadu.com",            ttl = 3600, priority = 10 },
    { name = "efhd.dev", type = "MX",  value = "aspmx2.migadu.com",            ttl = 3600, priority = 20 },
    # migadu.com DKIM+ARC, SPF, DMARC
    { name = "key1._domainkey.efhd.dev", type = "CNAME", value = "key1.efhd.dev._domainkey.migadu.com", ttl = 1800 },
    { name = "key2._domainkey.efhd.dev", type = "CNAME", value = "key2.efhd.dev._domainkey.migadu.com", ttl = 1800 },
    { name = "key3._domainkey.efhd.dev", type = "CNAME", value = "key3.efhd.dev._domainkey.migadu.com", ttl = 1800 },
    { name = "efhd.dev",                 type = "TXT",   value = "v=spf1 include:spf.migadu.com -all",  ttl = 1800 },
    { name = "_dmarc.efhd.dev",          type = "TXT",   value = "v=DMARC1; p=quarantine;",             ttl = 1800 },
    # migadu.com mail client autodiscovery records
    { name = "autoconfig.efhd.dev",         type = "CNAME", value = "autoconfig.migadu.com",   ttl = 3600 },
    {
      name = "_autodiscover._tcp.efhd.dev",
      type = "SRV",
      value = "autodiscover.migadu.com",
      ttl  = 3600,
      data = {
        name     = "@",
        service  = "_autodiscover",
        proto    = "_tcp",
        port     = 443
        priority = 0,
        weight   = 1,
      },
    },
    {
      name = "_submissions._tcp.efhd.dev",
      type = "SRV",
      ttl  = 3600,
      value = "smtp.migadu.com",
      data = {
        name     = "@",
        service  = "_submissions",
        proto    = "_tcp",
        port     = 465
        priority = 0,
        weight   = 1,
      },
    },
    {
      name = "_imaps._tcp.efhd.dev",
      type = "SRV",
      ttl  = 3600,
      value = "imap.migadu.com",
      data = {
        name     = "@",
        service  = "_imaps",
        proto    = "_tcp",
        port     = 993
        priority = 0,
        weight   = 1,
      },
    },
    {
      name = "_pop3s._tcp.efhd.dev",
      type = "SRV",
      ttl  = 3600,
      value = "pop.migadu.com",
      data = {
        name     = "@",
        service  = "_pop3s",
        proto    = "_tcp",
        port     = 995
        priority = 0,
        weight   = 1,
      },
    },
  ]
}
