# Running etcd in docker on Nomad OR How to run SRV discovery services with Consul DNS

This guide aims to provide a bare-bones insecure `etcd` deployment. This is a simple job definition but has a couple of "gotchas" that warrant this post.

The deployment will have the following characteristics:

* There will be no hard-coded IP
* Containers will run in the bridge network

## Requirements

If the below requirements are not met, you won't be able to follow the guide successully.

* A running `nomad` deploment.
* A consul installation with `nomad` configured for it.

## More prerequisites

Follow the guide [here](https://learn.hashicorp.com/tutorials/consul/dns-forwarding) to enable consul DNS forwarding. After having finished with the guide you should be able to query DNS for `consul.service.consul`

### Gotcha #1: Getting docker to configure its containers with the proper DNS server

By default, docker configures DNS by copying the `/etc/resolv.conf` file to the container, if the network mode is `bridge`, according to [the official documentation](https://docs.docker.com/config/containers/container-networking/).  The gotcha here is the following: the containers cannot possibly  communicate with the loopback interface of the host, so docker does not simply "copy" the file -- it removes any entries that match the loopback.

If you've followed the `systemd-resolved` part of the Forwarding Consul DNS guide you will have a `/etc/resolv.conf` file that looks like this:

```bash
cat /etc/resolv.conf | grep -v '^#'

nameserver 127.0.0.53
options edns0 trust-ad
search .
```

You will be able to resolve from the host, but docker will have to resort to fallbacks, and none of them will involve passing the systemd-resolved stub resolver in, somehow.

#### Make sure your DNS server exposes on an interface other than loopback

For our `systemd-resolved` example above, we could expose the Stub DNS resolver on the `docker0` interface. The default is `172.17.0.1` :

```bash
cat /etc/systemd/resolved.conf | grep -v '^#'

[Resolve]
DNSStubListenerExtra=172.17.0.1
```

After that, we should run `sudo systemctl restart systemd-resolved` so the changes take effect.  We can check the logs and make sure that the unit is not failed with: `journalctl -u systemd-resolved`.

#### Make sure your docker containers get spawned with the DNS server configured

For that we can override each container spawn setting the DNS server, but that's too tedious. We can instead configure the docker daemon for this by adding the map entry:

```
cat /etc/docker/daemon.json | grep dns
  "dns": [ "172.17.0.1" ]
```

To the daemon configuration file. If there isn't any other configuration, the file should look like this:

```json
{
  "dns": [ "172.17.0.1" ]
}
```

After the above is saved in `/etc/docker/daemon.json` and the docker daemon restarted, any containers spawned will default to this DNS server. You can test this by running:

```bash
docker run ubuntu:latest cat /etc/resolv.conf
```

You should see `nameserver 172.17.0.1` in the contents

### The etcd configuration (tested with: v3.5.1)

Etcd requires knowledge of all peers on bootstrap. This is not easy to implement in an environment where the IPs and ports are dynamic by default, without jumping through several hoops. Thankfully `etcd` also provides the capability for service discovery via `SRV` records.

This is how our `config` section will look like for the task:

```hcl
    config {
        image = "gcr.io/etcd-development/etcd:v3.5.1-amd64"
        args = [
          "/usr/local/bin/etcd",
          "--name=node${NOMAD_ALLOC_INDEX}",
          "--discovery-srv=service.consul",
          "--initial-advertise-peer-urls=http://${NOMAD_ADDR_peer}",
          "--initial-cluster-token=seaweedfs",
          "--initial-cluster-state=new",
          "--advertise-client-urls=http://${NOMAD_ADDR_client}",
          "--listen-client-urls=http://0.0.0.0:2379",
          "--listen-peer-urls=http://0.0.0.0:2380",
        ]
        ports = ["peer", "client"]
    }
```

The `--discovery-srv` flag is the key. It requires the domain in which to perform discovery, but etcd is too opinionated: it wants *specific* records, it won't just let you add a SRV record for it to query. The record that etcd queries is:

```bash
_etcd-server._tcp.${DISCOVERY_SRV_FLAG_DOMAIN}
```

If we were to use SSL, the domain would be:

```bash
_etcd-server-ssl._tcp.${DISCOVERY_SRV_FLAG_DOMAIN}
```

I'm not too fond of this, but I'm sure the maintainers had a very good rationale for implementing SRV service-discovery this way.

### Gotcha #2: Configuring service discovery

A normal `service` stanza for nomad would be in the `task` stanza and look like this:

```hcl
    task "sometask" {
      ...
      service {
        name = "somename"
        tags = ["http"]
        port = "http"
        check {
          name = "alive"
          type = "tcp"
          interval = "30s"
          timeout = "2s"
        }
      }
    }
```

This means that after the task allocation is up, the service is going to be registered to consul along with a health check for consul to query every `interval`.

This will **not** work for us:

* we don't want to associate our distributed service's discovery mechanism with a health check that
  dynamically evicts endpoints from that mechanism. It's like a recipe for disaster
* `etcd` specifically immediately fails if the record is not defined, and nomad won't register an
  endpoint before it's up, even without a health check

The solution to our gotcha is *moving* the `service` stanza to the `group` level, like so:

```hcl
  group "somegroup" {
    ...
    service {
      name = "etcd-server"
      port = "peer"
    }
  }
```

This will have the endpoints register before the container is up and running, there will be a record for each etcd to read on spawn.

Here is my full `etcd.hcl` nomad file:

```hcl
job "etcd" {
  datacenters = ["homelab"]
  type = "service"

  group "etcd" {
    count = 3

    network {
      port "peer"  {
        to = 2380
      }
      port "client"  {
        to = 2379
      }
    }

    ephemeral_disk {
      migrate = true
      sticky  = true
      size    = 300
    }

    # group services register before any tasks is running; needed for etcd discovery
    service {
      name = "etcd-server"
      port = "peer"
    }

    task "etcd" {
      driver = "docker"
      config {
        image = "gcr.io/etcd-development/etcd:v3.5.1-amd64"
        args = [
          "/usr/local/bin/etcd",
          "--name=node${NOMAD_ALLOC_INDEX}",
          "--discovery-srv=service.consul",
          "--initial-advertise-peer-urls=http://${NOMAD_ADDR_peer}",
          "--initial-cluster-token=seaweedfs",
          "--initial-cluster-state=new",
          "--advertise-client-urls=http://${NOMAD_ADDR_client}",
          "--listen-client-urls=http://0.0.0.0:2379",
          "--listen-peer-urls=http://0.0.0.0:2380",
        ]
        ports = ["peer", "client"]
      }
      resources {
        cpu = 500
        memory = 512
      }
      service {
        name = "etcd"
        tags = [
          "http",
        ]
        port = "client"
        check {
          name = "alive"
          type = "tcp"
          interval = "30s"
          timeout  = "2s"
        }
      }
    }
  }
}
```
