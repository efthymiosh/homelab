# Provisioning with software

So we've got a set of machines up and running, and we can ssh to them!
That's awesome, isn't it? Well, not yet. We haven't yet "taken over" the infrastructure. We'll do so
when we can spawn and access workloads with ease. Let's go make that happen.

## Configuring DNS

The first thing we need is an easy way to reference the machines. Referencing them by IP is a recipe
for disaster and makes things inflexible and resistant to changes.

We can take the easy way out of leaking private IPs to public DNS (spoiler alert: we will) or we
could deploy our own DNS servers internally.

### Private DNS considerations

DNS servers are very mature software. We can get something like NSD or BIND to serve an internal
zone such as `int.mydomain.com` and register our records there. [blocky](https://0xerr0r.github.io/blocky/)
looks interesting too. What irks me about this is that the responsibility for the records,
hardware-wise, is going to be the same hardware that is going to take advantage of it. I would
seriously prefer if these were discrete, so they were discrete failure points. Setting alternative
DNS servers for the network also has the impact that these IPs must always be accessible. I might
want to turn off these machines to conserve energy.

I will entertain the private DNS deployment when I have ultralow-power hardware that I can dedicate
to the task (some Raspberry Pi or similar). 

### Bad Practices with Public DNS

Right, (namecheap)[namecheap.com] is my registrar of choice. Let's get a couple of short domains
there.

A public DNS provider that has a free tier and I don't mind paying in the future is
[cloudflare](www.cloudflare.com). Register the "site", move the nameservers over, done.

Super easy to set up an account for and setup DNS with. 

And now, terraform. We will express the DNS configuration as-code bringing us the power of writing
stuff down rather than clicking through the same UI over and over again. Something like this:

```hcl
module "efth_eu" {
  source = "./modules/cloudflare/zone_with_records"
  zone   = "efth.eu"
  records = [
    { name = "snu1.int.efth.eu", type = "A", value = "192.168.1.240", ttl = 86400 },
    { name = "snu2.int.efth.eu", type = "A", value = "192.168.1.241", ttl = 86400 },
    { name = "snu3.int.efth.eu", type = "A", value = "192.168.1.242", ttl = 86400 },
  ]
}
```

Excellent! Well, a bit silly since we're leaking private addresses in public dns, but it works for
our purposes. You can find the full source code for my homelab dns
[here](https://github.com/efthymiosh/homelab/tree/main/terraform).

We will also point a set of wildcard records to the IPs of each of the machines. This will help us
with some routing fun with traefik later on.

## The base for the workloads
