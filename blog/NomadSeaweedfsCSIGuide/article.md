# Providing Container Storage for Nomad using SeaweedFS

[Nomad](https://nomadproject.io) is an excellent container orchestration system developed by
HashiCorp and a great lightweight alternative to the
[Governor](https://translate.google.com/?sl=en&tl=el&text=Governor&op=translate)(Kubernetes). Nomad
by default starts barebones: It's a workload scheduler. It's most frequently paired with
[Consul](https://consul.io) to provide service-discovery capabilities to the workloads, most
commonly, but not limited to, containers.

In this guide we will explore providing the ability for container workloads to support flexible
state, regardless of the node they are scheduled in. We will delve into the (currently beta) feature of Nomad, CSI Plugins.

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
    -disk=ssd \
    -max="100"
KillSignal=SIGINT
Restart=always

[Install]
WantedBy=multi-user.target
```

Simplicity we'll just install the filer on one node. The filer requires a database backend,
and we're going to use a default file-based backend. See the [wiki](https://github.com/chrislusf/seaweedfs/wiki/Directories-and-Files) for more information. Service file:

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

### CSI Plugin

We'll deploy the CSI plugin via Nomad:

```hcl
job "seaweedfs-plugin" {
  datacenters = ["dc1"]
  type = "system" # one on each node.

  group "csi" {
    task "csi" {
      driver = "docker"

      config {
        # We're stabilizing on a Digest as the maintainer only releases `latest` and `dev` tags
        image = "chrislusf/seaweedfs-csi-driver@sha256:fc6a55cd609687ccc3df5765fbddb8742089e68546fa9ceed246bc4821b1955e"
        privileged = true
        args = [
          "--endpoint=unix:///csi/csi.sock",
          "--filer=192.0.2.1:8888",
          "--nodeid=${node.unique.name}",
          "--cacheCapacityMB=1000",
          "--cacheDir=/tmp",
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

Notice the `privileged = true` in the docker config: This needs to be configured at the node client
level, make sure the [docker driver
configuration](https://www.nomadproject.io/docs/drivers/docker#privileged) has it enabled.

That's it! Your CSI plugin should be showing in the `Storage > Plugins` section of nomad, as a healthy set of containers!

Let's verify that all is in working order with a sample job:

```hcl
```

Executing `nomad stop sample-persistent` and re-running the job should give us ..
