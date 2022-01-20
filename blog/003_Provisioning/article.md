# Journey, Part 3: Provisioning with software

So we've got a set of machines up and running, and we can ssh to them!
That's awesome, isn't it? Well, not yet. We haven't yet "taken control" over the infrastructure.
We'll do so when we can spawn and access workloads with ease. Let's go make that happen.

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
prefer if these were discrete, so they were discrete failure points. Setting alternative
DNS servers for the network also has the impact that these IPs must always be accessible. I might
want to turn off these machines to conserve energy.

I will entertain the private DNS deployment when I have ultralow-power hardware that I can dedicate
to the task (some Raspberry Pi or similar). 

### Bad Practices with Public DNS

Right, [namecheap](namecheap.com) is my registrar of choice. Let's get a couple of short domains
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
* ~~SeaweedFS~~ GlusterFS with its CSI plugin, to provide persistent container storage.
* Prometheus, to monitor the above components and anything else
* Loki, to ingest all logs and make them easily accessible
* Grafana, to visualize monitoring and logging

Other than the deployment of nomad, consul and seaweedfs, which is going to be defined in ansible,
everything else will be shipped on nomad as a workload. To express this is a more declarative manner
the nomad workloads will be defined using the nomad operator for terraform. The operator is,
thankfully, little more than a wrapper on top of the nomad job definition files.

### Consul & Nomad

The ansible folder for nomad, consul and seaweedfs can be found
[here](https://github.com/efthymiosh/homelab/tree/main/ansible) on my homelab repository. The ansible
roles do not contain [handlers](https://docs.ansible.com/ansible/latest/user_guide/playbooks_handlers.html).
This is by design, as at some point in the future I'll be moving to images. I do not plan to be
tampering too much with the roles on live machines. If I find that I do, I'll implement conditional
handlers.

With consul being a distributed and highly available KV store, we have a resilient backend to use
for terraform. It's independent of anything that terraform will manage and provides resiliency and
flexibility compared to my laptop's disk. Easy to backup with `consul kv export`, too.

Fun fact, I initially provided the nomad provider URL for terraform and the consul state backend URL
for terraform via port 80. Which is perfectly fine since traefik is configured to forward to them.
Except traefik is managed via terraform and any changes to traefik break connectivity to both the
target (nomad) and the state backend. That was a not-so-fun moment when I realised the hard way :)

### Traefik

Traefik is setup as a nomad system job. It has the `NET_BIND_SERVICE` capability and binds port 80
(443 to come). It is then configured to forward to any consul services that have the `routed` tag,
so let's say, a consul service is defined via nomad like so:

```hcl
job "prometheus {
...
      service {
        name = "prometheus"
        tags = [
          "http",
          "routed",
          "monitored",
        ]
        port = "http"
      }
...
```
 
Since the service has the `routed` tag, traefik picks it up and uses the default
http host-header routing rule, which matches the wildcard record. Magic!

### Seaweedfs

On seaweedfs, what a charm! Super straightforward to understand the docs and deploy. Boy does it look
opinionated! What's up with the `scaffold` subcommand, just give us configuration samples in the
docs. It doesn't look like it's doing something dynamic, it doesn't even require a running `weed`.
First piece of software I see that requires a prometheus gateway while running as a
service! I suppose the maintainer had very good reasons to abuse prometheus like that,
as it's just the master service. The rest of them expose normal `/metrics` endpoints for prometheus.

So, apparently the `master` manages the `volume`, which is responsible for writing and
reading data. The `filer` provides the filesystem and s3 functionality (and more).
The filer is the service the CSI plugin will integrate with. It needs state to keep the file metadata.
The ansible example wasn't really great (read: not overkill enough) since it just deployed it on
one specific host with a leveldb backend.

So, I went on to deploy a etcd cluster to replace the leveldb, so I could have multiple
filers with the same state. That was fun!  [Update: ..It was also [completely
unnecessary](https://github.com/chrislusf/seaweedfs/wiki/Filer-Store-Replication)]
I'll write up spawning etcd into a guide, and another one for the CSI plugin.

Comparing to the Kubernetes templates required to spawn the CSI plugin it's so much simpler in
nomad! That said, and not sure if I'm missing something, there is no provided way to modify volume
ownership. Maybe in the future. [It is a thing,
though](https://kubernetes-csi.github.io/docs/support-fsgroup.html).

Seaweedfs has some quirks but I really want it to be awesome. I'm not 100% sure that it's working
like a champ, though. I observed weird issues relating to storage in two cases:

* When trying to import the `Node Exporter` grafana dashboard (one of the largest, probably), having
  grafana configured with SQLite crashed the server every single time. Very low confidence that seaweedfs
  is the culprit here, since moving the state to a PostgreSQL (over seaweedfs again) seems fine
* Prometheus after a restart experienced a state corruption. Again, super low confidence. I didn't
  configure a `kill_timeout` for the nomad task, which I really should have.

Damn, the default `kill_timeout` is 5 seconds. That's way too low for anything where the timeout
matters. Let's set the client max for all crucial workloads.

#### Half-arsed troubleshooting interim

After the `kill_timeout` fix, prometheus looked to be working fine, but some time later..

```
ts=2022-01-16T02:06:31.078Z caller=main.go:1166 level=info msg="Completed loading of configuration file" fil2s
ts=2022-01-16T02:06:31.078Z caller=main.go:897 level=info msg="Server is ready to receive web requests."
ts=2022-01-16T04:21:42.309Z caller=compact.go:518 level=info component=tsdb msg="write block" mint=1642296099s
ts=2022-01-16T04:21:42.347Z caller=db.go:816 level=error component=tsdb msg="compaction failed" err="compacte"
ts=2022-01-16T04:21:44.693Z caller=compact.go:518 level=info component=tsdb msg="write block" mint=1642296099s
```

Some etcd warnings:

```json
{
  "level": "warn",
  "ts": "2022-01-16T11:33:08.264Z",
  "caller": "etcdserver/util.go:166",
  "msg": "apply request took too long",
  "took": "490.415639ms",
  "expected-duration": "100ms",
  "prefix": "read-only range ",
  "request": "key:\"/buckets/tsdb\\00001FSHAK3ECJGXEW1EBQHE6N28S.tmp-for-creation\" ",
  "response": "range_response_count:1 size:111"
}
```

Right.


First, let's explore if it's worth it to simplify the architecture. We don't need the separate backend
since the `filer` service can intercommunicate with other filer services.

```
W0115 21:50:59     1 filer_server.go:141] skipping default store dir in ./filerldb2
E0115 22:01:26     1 filer_grpc_server_sub_meta.go:70] processed to 2022-01-15 22:01:26.360988691 +0000 UTC: rpc error: code = Unavailable desc = transport is closing
E0116 00:49:57     1 filer_grpc_server_sub_meta.go:70] processed to 2022-01-16 00:49:57.161912084 +0000 UTC: rpc error: code = Unavailable desc = transport is closing
E0116 00:52:16     1 filer_grpc_server_sub_meta.go:70] processed to 2022-01-16 00:52:16.408402275 +0000 UTC: rpc error: code = Unavailable desc = transport is closing
W0115 21:50:59     1 filer_server.go:141] skipping default store dir in ./filerldb2
E0115 22:01:26     1 filer_grpc_server_sub_meta.go:70] processed to 2022-01-15 22:01:26.360988691 +0000 UTC: rpc error: code = Unavailable desc = transport is closing
E0116 00:49:57     1 filer_grpc_server_sub_meta.go:70] processed to 2022-01-16 00:49:57.161912084 +0000 UTC: rpc error: code = Unavailable desc = transport is closing
E0116 00:52:16     1 filer_grpc_server_sub_meta.go:70] processed to 2022-01-16 00:52:16.408402275 +0000 UTC: rpc error: code = Unavailable desc = transport is closing
E0116 07:52:17     1 filer_grpc_server_sub_meta.go:133] processed to 2022-01-16 07:52:16.723646878 +0000 UTC: rpc error: code = Unavailable desc = transport is closing
E0116 08:17:17     1 filer_grpc_server_sub_meta.go:133] processed to 2022-01-16 08:17:16.750366716 +0000 UTC: rpc error: code = Unavailable desc = transport is closing
E0116 08:32:17     1 filer_grpc_server_sub_meta.go:133] processed to 2022-01-16 08:32:16.734884716 +0000 UTC: rpc error: code = Unavailable desc = transport is closing
E0116 08:32:17     1 filer_grpc_server_sub_meta.go:133] processed to 2022-01-16 08:32:16.734884716 +0000 UTC: rpc error: code = Unavailable desc = transport is closing
E0116 10:09:13     1 filer_grpc_server_sub_meta.go:70] processed to 2022-01-16 10:09:13.892412223 +0000 UTC: rpc error: code = Unavailable desc = transport is closing
```

So a connection is closing and (first assumption) something has not finished processing up to where
it should have. Look at that log message. The more you look at it the more pointless it looks.
The timestamp print, which is just a more verbose print of `time.Now()` feels like something the dev
needs in debug builds, not something that communicates an error during real use.

I have to open the code to understand what the log message means.
Right, clone the repo, switch to the `2.85` tag, open up `filer_grpc_server_sub_meta.go`. Turns out
the timestamp is not the current time, but the time the process experienced a "ResumeFromDiskError".

But what disk is the filer resuming from? This is a `subscribeLocalMetadata` function. The filer is
not a service that should have anything to do with disk. I don't want to delve into the maintainer's
mind to understand what's going on here.

I don't want to debug this, things like `time.Sleep(1127 * time.Millisecond)` in the code are
turning me off.

And why are there a ton of seaweedfs volumes?

```bash
$ /opt/weed shell
master: localhost:9333 filers: [192.168.1.240:8888 192.168.1.242:8888 192.168.1.241:8888]
> volume.list
Topology volumeSizeLimit:8192 MB ssd(volume:0/0 active:0 free:0 remote:0) hdd(volume:60/300
active:60 free:24)
...
        Disk hdd(volume:21/100 active:21 free:79 remote:0)
          volume id:1 size:3992680 file_count:400 replica_placement:1 version:3 modified_at_second:1642336200
          volume id:2 size:3018792 file_count:350 replica_placement:1 version:3 modified_at_second:1642336200
          volume id:5 size:3029944 file_count:381 replica_placement:1 version:3 modified_at_second:1642336140
          volume id:7 size:654144 collection:"ghost_content" file_count:19 delete_count:7 deleted_byte_count:70446 replica_placement:1 version:3 compact_revision:4
...
          volume id:64 size:18654696 collection:"tsdb" file_count:18 delete_count:11 deleted_byte_count:4933033 replica_placement:1 version:3 compact_revision:31 modified_at_second:1642336189
          volume id:65 size:44672312 collection:"tsdb" file_count:73 delete_count:58 deleted_byte_count:14569467 replica_placement:1 version:3 compact_revision:19 modified_at_second:1642336188
...
        Disk hdd total size:175160552 file_count:3819 deleted_file:1367 deleted_bytes:41443617
          volume id:64 size:18654696 collection:"tsdb" file_count:18 delete_count:11 deleted_byte_count:4933033 replica_placement:1 version:3 compact_revision:31 modified_at_second:1642336189
          volume id:66 size:14769672 collection:"tsdb" file_count:14 delete_count:7 deleted_byte_count:3168941 replica_placement:1 version:3 compact_revision:33 modified_at_second:1642336189
        Disk hdd total size:98093048 file_count:4620 deleted_file:2069 deleted_bytes:17783368
```

Now that is a proper riddle. `tsdb` and `loki` are append-only, and `ghost` has been idling for
ages. [Update: After clearing all state from everything and respawning, I can again see 60 volumes
spawned for the 4 CSI volumes + the default. Since the default is empty and not managed with Nomad
we can safely deduce that the 12 volume thing is a minimum, for some reason. Probably my tuning.

The `volume` and `master` logs don't show any interesting info.

The `master` logs do though:

```bash
Jan 16 06:21:05 snu1 weed[690]: I0116 06:21:05   690 volume_layout.go:373] Volume 66 becomes unwritable
Jan 16 06:21:05 snu1 weed[690]: I0116 06:21:05   690 topology_vacuum.go:72] 1 Start vacuuming 66 on 192.168.1.242:8083
Jan 16 06:21:05 snu1 weed[690]: I0116 06:21:05   690 topology_vacuum.go:72] 0 Start vacuuming 66 on 192.168.1.241:8083
Jan 16 06:21:05 snu1 weed[690]: I0116 06:21:05   690 topology_vacuum.go:99] Complete vacuuming 66 on 192.168.1.241:8083
Jan 16 06:21:05 snu1 weed[690]: I0116 06:21:05   690 topology_vacuum.go:99] Complete vacuuming 66 on 192.168.1.242:8083
Jan 16 06:21:05 snu1 weed[690]: I0116 06:21:05   690 topology_vacuum.go:123] Start Committing vacuum 66 on 192.168.1.241:8083
Jan 16 06:21:05 snu1 weed[690]: I0116 06:21:05   690 topology_vacuum.go:137] Complete Committing vacuum 66 on 192.168.1.241:8083
Jan 16 06:21:05 snu1 weed[690]: I0116 06:21:05   690 topology_vacuum.go:123] Start Committing vacuum 66 on 192.168.1.242:8083
Jan 16 06:21:06 snu1 weed[690]: I0116 06:21:06   690 topology_vacuum.go:137] Complete Committing vacuum 66 on 192.168.1.242:8083
Jan 16 06:21:06 snu1 weed[690]: I0116 06:21:06   690 volume_layout.go:386] Volume 66 becomes writable
Jan 16 06:21:06 snu1 weed[690]: I0116 06:21:06   690 volume_layout.go:373] Volume 61 becomes unwritable
Jan 16 06:21:06 snu1 weed[690]: I0116 06:21:06   690 topology_vacuum.go:72] 1 Start vacuuming 61 on 192.168.1.241:8083
Jan 16 06:21:06 snu1 weed[690]: I0116 06:21:06   690 topology_vacuum.go:72] 0 Start vacuuming 61 on 192.168.1.240:8083
Jan 16 06:21:06 snu1 weed[690]: I0116 06:21:06   690 topology_vacuum.go:99] Complete vacuuming 61 on 192.168.1.241:8083
Jan 16 06:21:06 snu1 weed[690]: I0116 06:21:06   690 topology_vacuum.go:99] Complete vacuuming 61 on 192.168.1.240:8083
Jan 16 06:21:06 snu1 weed[690]: I0116 06:21:06   690 topology_vacuum.go:123] Start Committing vacuum 61 on 192.168.1.240:8083
Jan 16 06:21:06 snu1 weed[690]: I0116 06:21:06   690 topology_vacuum.go:137] Complete Committing vacuum 61 on 192.168.1.240:8083
Jan 16 06:21:06 snu1 weed[690]: I0116 06:21:06   690 topology_vacuum.go:123] Start Committing vacuum 61 on 192.168.1.241:8083
Jan 16 06:21:06 snu1 weed[690]: I0116 06:21:06   690 topology_vacuum.go:137] Complete Committing vacuum 61 on 192.168.1.241:8083
Jan 16 06:21:06 snu1 weed[690]: I0116 06:21:06   690 volume_layout.go:386] Volume 61 becomes writable
Jan 16 06:21:06 snu1 weed[690]: I0116 06:21:06   690 volume_layout.go:373] Volume 62 becomes unwritable
```

It's always volumes 61-65 vacuuming, meaning that it *does* use just a few volumes in reality?

For an application complaining about broken data, the underlying FS is not complaining enough. Let's
go more PoC. We'll reset everything and remove the dependency on `etcd`.

* After having deployed the filers and left it running for a few hours, prometheus started complaining
  about tsdb.
* Rebooting the machine postgres was running on caused postgres to fail as well, with invalid data.
* Rebooting the machine had prometheus restart, and caused it to stop emitting the  tsdb compaction
  errors: This demonstrates inconsistent state and not a problem with the behavior the applications
  expects.

I'm not sure if the applications requires functions that the FS can't provide, and thus fail.
Regardless, it's not working out and I'm not willing to dig deeper. Storage should be **boring**.

### Is boring good? glusterFS

I kinda familiarized with glusterFS when I was part of the team that operated a legacy InfiniDB
cluster that employed it. I didn't really love it, but I didn't really hate it. Boring enough?
Perhaps.

Getting it deployed was fairly straightforward. As with other applications from the Age of
Serverpet Administration, its prevalent management manner is a redundant operator you issue
commands on via its cli. Got a replicated volume up and running in no-time, ready for CSI
integration.

The CSI integration never came, though. What a mess.. The glusterfs-csi-driver github
project had a headline that started with `DEPRECATED` without mentioning anything in the README.
The [kadalu](https://github.com/kadalu/kadalu) project that leverages glusterfs is a one-stop-shop
for storage for kubernetes, on kubernetes. I would just transform it to nomad, but it utilizes
some neopattern providing an executable CLI to manage the underlying mechanism.. FML.

### In search for storage

As I am going through the [CSI plugins table](https://kubernetes-csi.github.io/docs/drivers.html)
on CSI Developers Documentation, I stumbled upon
[democratic-csi](https://github.com/democratic-csi/democratic-csi). This looks pretty cool. We'll
keep it for future reference. If only I had a NAS with RAID.. Well I do have a NAS with RAID, but
I'm not going to keep it up 24/7 to server some storage to containers.

What's interesting is that there are CSIs for pretty much all th

Maybe boring

### Prometheus & Grafana

Prometheus is set up to autodiscover anything with the `monitored` consul tag. Both Prometheus and
Grafana are forwarded via traefik.

There are some static targets configured for Prometheus, `consul` and `nomad`. The rest of the
non-nomad-managed targets are defined directly in consul configuration files as services with the
`monitored` tag.

### Loki

This is something that I was sure I was going to spend a significant amount of time on, but I found
an awesome guide in Adrian Todorov's blog: [Logging on Nomad and log aggregation with
Loki](https://atodorov.me/2021/07/09/logging-on-nomad-and-log-aggregation-with-loki/). What a
wonderful article.

After having followed it with the Vector approach, logs ingestion is working great! I'd like to
bring in the systemd logs. This means Vector will have to be exposed to journald files, which would
be yet another nomad client change. I don't think it makes sense. I'll just deploy it on the host
nodes. Perhaps nomad `raw_exec` for some tasks makes sense.
