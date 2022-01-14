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

We will ship the following components on the machines:

* Nomad, to provide us with workload orchestration
* Consul, to provide us with service-discovery exposed via API and DNS and a KV store
* Traefik, to glue an endpoint with each consul service using its native consulCatalog integration
* SeaweedFS with its CSI plugin, to provide persistent container storage.
* Prometheus, to monitor the above components and anything else
* Loki, to ingest all logs and make them easily accessible
* Grafana, to visualize monitoring and logging

Other than the deployment of nomad, consul and seaweedfs, which is going to be defined in ansible,
everything else will be shipped on nomad as a workload. To express this is a more declarative manner
the nomad workloads will be defined using the nomad operator for terraform. The operator is,
thankfully, little more than a wrapper on top of the nomad job definition files.

The ansible folder for nomad, consul and seaweedfs can be found
[here](https://github.com/efthymiosh/homelab/tree/main/ansible) on my homelab repository. The ansible
roles do not contain [handlers](https://docs.ansible.com/ansible/latest/user_guide/playbooks_handlers.html).
This is by design, as at some point in the future I'll be moving to images. I do not plan to be
tampering too much with the roles on live machines. If I find that I do, I'll implement conditional
handlers.

With consul being a distributed and highly available KV store, we have a resilient backend to use
for terraform. It's independent of anything that terraform will manage and provides resiliency and
flexibility compared to my laptop's disk. Easy to backup with `consul export`, too.

Fun fact, I initially provided the nomad provider URL for terraform and the consul state backend URL
for terraform via port 80. Which is perfectly fine since traefik is configured to forward to them.
Except traefik is managed via terraform and any changes to traefik break connectivity to both the
target (nomad) and the state backend. That was a not-so-fun moment when I realised the hard way :)

On seaweedfs, what a charm! Super straightforward to understand the docs and deploy. Boy does it look
opinionated! What's up with the `scaffold` subcommand, just give us configuration samples in the
docs. And first piece of software I see that requires a prometheus gateway while running as a
service! I suppose the maintainer had very good reasons to abuse prometheus like that,
as it's just the master service that may be configured like that.

So on seaweed, apparently the `master` manages the `volume`, which is responsible for writing and
reading data. The `filer` provides the filesystem, and s3 functionality. It's the service the CSI
plugin will integrate with. The filer needs state to keep the file metadata. The ansible example
wasn't really great (read: not overkill enough) since it just deployd it on one specific host with a
leveldb backend.

So, I went on to deploy a etcd cluster to replace the leveldb, so I could have multiple
filers with the same state. That was fun! I'll write it up into a guide. And another one for the CSI plugin.

Comparing to the Kubernetes templates required to spawn the CSI plugin it's so much simpler in
nomad.

A job definition with the plugin, and a special configuration to mount a socket in the plugin's
container. That's it. On the Kubernetes side, there's even `CustomResourceDefinitions` in there. I
get that some things are barebones so that they can be expanded on, but isn't CSI supposed to be
the interface?


Other than its little quirks, seaweedfs ..
