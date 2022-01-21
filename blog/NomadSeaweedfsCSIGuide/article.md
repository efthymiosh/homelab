# Providing Container Storage for Nomad using SeaweedFS

[Nomad](https://nomadproject.io) is an excellent container orchestration system developed by
HashiCorp and a great lightweight alternative to the
[Governor](https://translate.google.com/?sl=en&tl=el&text=Governor&op=translate)(Kubernetes). Nomad
by default starts barebones: It's a workload scheduler. It's most frequently paired with
[Consul](https://consul.io) to provide service-discovery capabilities to the workloads, most
commonly, but not limited to, containers.

In this guide we will explore providing the ability for container workloads to support flexible
state, regardless of the node they are scheduled in. We will delve into the (currently beta) feature of Nomad, CSI Plugins.

## A word of warning

As of the date of writing this guide, seaweedFS does not work well with most demanding workloads,
at least with the configuration used in the guide. I have tried 4 different workloads:

1. sqlite3 database: works well
2. mysql database: ultraminor load, state corruption prevented database to boot
3. prometheus tsdb: state corruption while trying to compact, blocks had erroneous data
4. loki, mostly appending files: no errors discovered

## Requirements

If the below requirements are not met, you won't be able to follow the guide successully.

* A running `nomad` deploment.
* A consul installation with `nomad` configured for it.
* All nomad client nodes are able to query DNS for consul services. Guide
[here](https://learn.hashicorp.com/tutorials/consul/dns-forwarding)

## Assumptions

You can easily find workarounds for the below, but the guide will assume the scenario
described below.

* the target machines are running a linux distribution with systemd. 
* SeaweedFS will be deployed on 3 target machines with IPs ranging from `192.0.2.1` to `192.0.2.3`.

## SeaweedFS

[SeaweedFS](http://seaweedfs.github.io/) is a Distributed Filesystem and Object Store written by
Chris Lu. Its most stunning feature is how simple it is to get up and running: Let's get started!

### Deployment

To get us started, let's fetch the latest release from the SeaweedFS
[releases page](https://github.com/chrislusf/seaweedfs/releases). Make sure you pick the right
executable for your architecture and OS, there are *a lot* of archives. Extract the main
executable, `weed`, to a proper directory, `/usr/local/bin/`:

```
curl -Lo weed.tar.gz https://github.com/chrislusf/seaweedfs/releases/download/2.85/linux_amd64.tar.gz
tar xvf weed.tar.gz
chmod  755 weed
sudo chown root:root weed
sudo mv weed /usr/local/bin/
```

Next, create the necessary directories for SeaweedFS:

```
sudo mkdir -p /var/lib/seaweedfs/data/ # path to volumes directory
sudo mkdir -p /var/lib/seaweedfs/master/ # path to master metadata dir
sudo mkdir -p /var/lib/seaweedfs/filer/ # path to the filer store and conf dir
```

Install the following systemd service files into `/etc/systemd/system/` on each of the target
machines:

```ini
# seaweedfs_master.service
[Unit]
Description=Seaweed Distributed FileSystem Master
Wants=network-online.target
After=network.target network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/weed \
    master \
    -mdir="/var/lib/seaweedfs/master/" \
    -ip="192.0.2.1" \
    -peers="192.0.2.1:9333,192.0.2.2:9333,192.0.2.3:9333" \
    -volumeSizeLimitMB=8192 \
    -defaultReplication="001"
KillSignal=SIGINT
Restart=always

[Install]
WantedBy=multi-user.target
```

Make sure to replace the value of the `-ip` flag on the master service with the corresponding IP of
each machine. Please note that `volumeSizeLimitMB` steps down from the default of 30000, assuming
small disks. The `defaultReplication` will keep a replica copy to a volume on the same "datacenter"
and "rack". Read through the [official wiki](https://github.com/chrislusf/seaweedfs/wiki) for more
information about these values.

Next:

```ini
# seaweedfs_volume.service
[Unit]
Description=Seaweed Distributed FileSystem Volume
Wants=network-online.target
After=network.target network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/weed \
    volume \
    -dir="/var/lib/seaweedfs/data/" \
    -mserver="192.0.2.1:9333,192.0.2.2:9333,192.0.2.3:9333" \
    -port=8083 \
    -max="100"
KillSignal=SIGINT
Restart=always

[Install]
WantedBy=multi-user.target
```

The filer requires a database backend, and we're going to use a default file-based backend
leveraging leveldb. See the [wiki](https://github.com/chrislusf/seaweedfs/wiki/Directories-and-Files)
for more information.  Even though it's going to be using local storage, the metadata will be
replicated between the filer instances, see
[here](https://github.com/chrislusf/seaweedfs/wiki/Filer-Store-Replication) for an interesting read!
The service file:

```ini
# seaweedfs_filer.service
[Unit]
Description=Seaweed Distributed FileSystem Filer
Wants=network-online.target
After=network.target network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/var/lib/seaweedfs/filer/
ExecStart=/usr/local/bin/weed \
    filer \
    -ip="192.0.2.1" \
    -port={{ seaweedfs_filer_port }} \
    -master="192.0.2.1:9333,192.0.2.2:9333,192.0.2.3:9333"
KillSignal=SIGINT
Restart=always

[Install]
WantedBy=multi-user.target
```

After installing these service files on the machines, turn them on.

First, the master nodes:

```
systemctl enable seaweedfs_master.service
systemctl start seaweedfs_master.service
# after switching all master nodes online, the logs should look somewhat like this:
journalctl -fu seaweedfs_master.service 
Jan 12 00:47:37 node1 systemd[1]: Started Seaweed Distributed FileSystem Master.
Jan 12 00:47:37 node1 weed[99180]: I0112 00:47:37 99180 file_util.go:23] Folder /var/lib/seaweedfs/master/ Permission: -rwxr->
Jan 12 00:47:37 node1 weed[99180]: I0112 00:47:37 99180 master.go:170] current: 192.0.2.1:9333 peers:192.0.2.1:>
Jan 12 00:47:37 node1 weed[99180]: I0112 00:47:37 99180 master_server.go:121] Volume Size Limit is 8192 MB
Jan 12 00:47:37 node1 weed[99180]: I0112 00:47:37 99180 master.go:125] Start Seaweed Master 30GB 2.85 19555385f7b99bce0e1f562>
Jan 12 00:47:37 node1 weed[99180]: I0112 00:47:37 99180 raft_server.go:71] Starting RaftServer with 192.0.2.1:9333
Jan 12 00:47:37 node1 weed[99180]: I0112 00:47:37 99180 raft_server.go:131] current cluster leader:
Jan 12 00:47:55 node1 weed[99180]: I0112 00:47:55 99180 master.go:148] Start Seaweed Master 30GB 2.85 19555385f7b99bce0e1f562>
Jan 12 00:47:57 node1 weed[99180]: I0112 00:47:57 99180 masterclient.go:72] connect to 192.0.2.2:9333: rpc error: code>
Jan 12 00:47:57 node1 weed[99180]: I0112 00:47:57 99180 masterclient.go:72] connect to 192.0.2.3:9333: rpc error: code>
Jan 12 00:47:57 node1 weed[99180]: I0112 00:47:57 99180 masterclient.go:79] No existing leader found!
Jan 12 00:47:57 node1 weed[99180]: I0112 00:47:57 99180 raft_server.go:158] Initializing new cluster
Jan 12 00:47:57 node1 weed[99180]: I0112 00:47:57 99180 master_server.go:164] leader change event:  => 192.0.2.1:9333
Jan 12 00:47:57 node1 weed[99180]: I0112 00:47:57 99180 master_server.go:166] [ 192.0.2.1:9333 ] 192.0.2.1:9333>
Jan 12 00:48:00 node1 weed[99180]: I0112 00:48:00 99180 master_grpc_server.go:262] + client master@192.0.2.2:9333
Jan 12 00:48:00 node1 weed[99180]: I0112 00:48:00 99180 master_grpc_server.go:262] + client master@192.0.2.1:9333
Jan 12 00:48:00 node1 weed[99180]: I0112 00:48:00 99180 master_grpc_server.go:262] + client master@192.0.2.3:9333
```

Then, the volume nodes:

```
systemctl enable seaweedfs_volume.service
systemctl start seaweedfs_volume.service
```

Finally, the filer node:

```
systemctl enable seaweedfs_filer.service
systemctl start seaweedfs_filer.service
```

Great! We've now got `weed` up and running!

## CSI Plugin

We'll deploy the CSI plugin via Nomad:

```hcl
job "seaweedfs-plugin" {
  datacenters = ["dc1"] # do not omit to substitute this for your nomad's dc
  type = "system"

  constraint {
    operator = "distinct_hosts"
    value = true
  }

  group "csi" {
    task "csi" {
      driver = "docker"

      config {
        image = "chrislusf/seaweedfs-csi-driver@sha256:fc6a55cd609687ccc3df5765fbddb8742089e68546fa9ceed246bc4821b1955e"
        privileged = true
        args = [
          "--endpoint=unix:///csi/csi.sock",
          "--filer=${attr.unique.network.ip-address}:8888",
          "--nodeid=${node.unique.name}",
        ]
      }

      csi_plugin {
        id        = "seaweedfs-csi"
        type      = "node"
        mount_dir = "/csi"
      }
    }
  }
}
```

And another for the `controller`
```
job "seaweedfs-plugin-controller" {
  datacenters = ["dc1"]
  type = "service"

  update {
    # use forced updates instead of deployments, we never want more than 1 running
    max_parallel = 0
  }

  group "node" {
    count = 1

    task "driver" {
      driver = "docker"

      config {
        image = "chrislusf/seaweedfs-csi-driver@sha256:fc6a55cd609687ccc3df5765fbddb8742089e68546fa9ceed246bc4821b1955e"
        privileged = true
        args = [
          "--endpoint=unix:///csi/csi.sock",
          "--filer=${attr.unique.network.ip-address}:8888",
          "--nodeid=controller",
        ]
      }

      csi_plugin {
        id        = "seaweedfs-csi"
        type      = "controller"
        mount_dir = "/csi"
      }
    }
  }
}
```

* Notice the `privileged = true` in the docker config: This needs to be configured at the node client
level, make sure the [docker driver
configuration](https://www.nomadproject.io/docs/drivers/docker#privileged) has it enabled.
* The image we are using is hard-coded to a specific Digest instead of a more dynamic tag. This is
  because the maintainer only utilizes `:latest` and `:dev` tags. I don't feel comfortable enough
having this updating dynamically, even if it is for my homelab.
* The image and argument for the `node` plugin and the `controller` plugin are pretty much
  identical. This is how the plugin is spawned using Helm and Kubernetes templates. [*Note:* I'm not
sure if we could get away with listing the `node` plugin deployment as a `monolith`, this depends on
its implementation, and there is no indicator that this could work.] 

Let's verify that all is in working order:

```bash
nomad plugin status
Container Storage Interface
ID        Provider              Controllers Healthy/Expected  Nodes Healthy/Expected
seaweedf  seaweedfs-csi-driver  1/1                           3/3
```

That's it! Your CSI plugin should also be showing in the `Storage > Plugins` section of nomad, as a
healthy set of containers!


## Using SeaweedFS volumes

First, let's register a volume to nomad:

```hcl
# my_volume.hcl
type = "csi"

plugin_id = "seaweedfs-csi"
id        = "my_volume_id"
name      = "my_volume_name"

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}

capacity_min = "1MiB"
capacity_max = "8GiB"
```

Issue `nomad create volume my_volume.hcl` to get the volume up and running.

Note that the CSI plugin registers a very uncommon but welcome access mode, multi-node-multi-writer:

```
$ nomad logs -stderr -job seaweedfs-plugin | grep 'access mode'
I0114 19:06:21     1 driver.go:96] Enabling volume access mode: SINGLE_NODE_WRITER
I0114 19:06:21     1 driver.go:96] Enabling volume access mode: MULTI_NODE_MULTI_WRITER
```

Time to deploy a sample job:
```hcl
job "ubuntu" {
  datacenters = ["dc1"]
  type = "service"

  group "ubuntu" {
    count = 1

    volume "my_volume" {
      type = "csi"
      source = "my_volume_name"
      attachment_mode = "file-system"
      access_mode = "single-node-writer"
    }
    task "ubuntu" {
      driver = "docker"
      config {
        image = "ubuntu:latest"
        args = ["sleep", "24h"]
      }
      resources {
        cpu = 500
        memory = 512
      }
      volume_mount {
        volume = "my_volume"
        destination = "/opt/data"
      }
    }
  }
}
```

```bash
# Follow through with these commands
$ nomad exec -job ubuntu bash
# echo 'test' > /opt/data/test.txt
```

If we open one of the filer endpoints in the browser, we can navigate to the file. For our example the url
would be :

```
http://192.0.2.1:8888/buckets/my_volume_name/
```

Executing `nomad stop ubuntu` and re-running the job should have the file readily available!

## Debugging

All seaweedfs services have logs, but we can also use the weed executable with its
`shell` subcommand.

What I found interesting was that if seaweedfs can't allocate a volume the error won't be exposed in
a way that you might be used to from actual filesystems. Filesystem structure will be fine, since
it's just `filer` metadata. You'll be able to create directories and touch files, but you won't be
able to add any content to the files.
