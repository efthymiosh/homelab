# Setting up the Tinkerbell bare-metal provisioner for your homelab

This guide aims to help provide a step-by-step container-based installation of tinkerbell for
home-lab purposes. After following this guide, you will have a tinkerbell setup on your controller
machine ready to take over and provision instances attempting to PXE boot on the same network as
the controller machine.

Use this guide if any of the below applies:

* you want a barebones starting point for deploying a permanent tinkerbell provisioner on your
container orchestrator of choice
* you want to digest how the components interconnect
* the official sandbox `docker-compose.yml` feels overwhelming

The guide assumes that you're already familar with [what tinkerbell is](https://tinkerbell.org/)
and vaguely familiar with [what its components are](https://docs.tinkerbell.org/).

Make sure to also read through
[Building an Ephemeral Homelab](https://metal.equinix.com/blog/building-an-ephemeral-homelab/).

We'll focus on getting a simple tinkerbell setup up and running while walking through
the configuration.

## Caveats

1. The official tinkerbell docker images are not versioned for human consumption, but are deployed
on [tags named after the git
short-sha](https://github.com/tinkerbell/boots/blob/129caee6916a2ef9a5cb4af216141654b0bc6e77/.github/workflows/ci.yaml#L52).
We'll be using the `:latest` tag for this guide, but for your actual deployment please stabilize to
sha tags by checking out what's available at [the container image hosting site](https://quay.io/organization/tinkerbell).

2. We'll be using `nomad` to get us started, but with a on-the-fly syntax translation on the
reader's part, the concepts should be applicable to `kubernetes`.

3. We'll be using *a lot* of `network_mode = host` for the nomad containers. In an ideal scenario
   where we have nomad deployed in our homelab, we'll have ways of discovering and addressing the
hosts in a different manner.

## Requirements

### docker 

Follow the official installation guide [here](https://docs.docker.com/get-docker/) |

### nomad

Quick and (very) dirty installation:

1. pick up the latest executable from [the official website](nomadproject.io)
2. install it into a folder that's in your `$PATH`
3. Create a file named `nomad.conf.hcl` with contents (we'll need that later on):

```hcl
data_dir = "/var/lib/nomad"

server {
    bootstrap_expect = 1
    enabled = true
}
client {
    enabled = true
    options = {
        "docker.volumes.enabled" = "true"
    }
}
```

4. issue `sudo nomad agent -log-level=INFO` to get nomad running in a barebones server+client mode
5. visit `localhost:4646` |

### tink CLI

Get it from the [tinkerbell sandbox releases page](https://github.com/tinkerbell/sandbox/releases): `tink-linux-*`.

Change its mode to executable with `chmod +x tink-linux-*`.
Move the file to a folder in your `$PATH`. The guide will assume you've renamed the executable to
`tink`.


## 1. Tink Server


### PostgreSQL

This step requires persistence. Let's create a folder to store postgresql state:

```bash
sudo mkdir -p /var/lib/nomad/postgresql
```

Tink depends on a postgresql database being up and running. Let's get one:

```hcl
job "postgres" {
  datacenters = ["dc1"]
  type = "service"

  group "postgres" {
    count = 1

    network {
      port  "db"  {
        static = 5432
      }
    }

    task "postgres" {
      driver = "docker"
      config {
        image = "postgres:14-alpine"
        network_mode = "host"
      }
      env {
        POSTGRES_DB="tinkerbell"
        POSTGRES_USER="tinkerbell"
        POSTGRES_PASSWORD="tinkerbell"
      }

      resources {
        cpu = 1000
        memory = 512
      }
    }
  }
}

```

Run the postgresql server and verify it's up and running:

```bash
$ nomad run postgresql.hcl
$ telnet localhost 5432
ctrl+]
quit
```

### Certificates 

The tink server employs gRPC for service intercommunication, and *requires* that certificates
are present, otherwise it fails initialization.

If you're feeling like "hold my beer": Get the certs ready and move on to the next section.

If you're physically shivering from `openssl x509` ptsd: We'll produce a CA certificate and use it
to sign a server certificate we'll create, using the `cfssl` helper tool from
[cloudflare](https://www.cloudflare.com/) in this section.

#### Requirements

| TOOL     | Installation |
| -------- | ------------ |
| `cfssl*` | Fetch the latest release of `cfssl` and `cfssljson` for your architecture/OS from its [github
page](https://github.com/cloudflare/cfssl). |


#### Generating the certificates

Let's drop to a shell and get started:

```bash
# Set the string to be used for the certificate attribute "locality".
export FACILITY="homelab"

# First, let's configure the CA CSR

cat <<EOH > ca-csr.json
{
  "CN": "Tinkerbell CA",
  "key": {
    "algo": "ecdsa",
    "size": 256
  },
  "names": [
    {
      "L": "$FACILITY"
    }
  ]
}
EOH

# Generate the CA certificate

cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

# Configure the server signing request. Make sure to replace the IPs with your controller's
# homelab network IP.

cat <<EOH > csr.json
{
  "CN": "Tinkerbell",
  "hosts": [
    "192.168.1.55",
    "192.168.1.19",
    "127.0.0.1",
    "localhost"
  ],
  "key": {
    "algo": "ecdsa",
    "size": 256
  },
  "names": [
    {
      "L": "$FACILITY"
    }
  ]
}
EOH

cat <<EOH > ca-config.json
{
  "signing": {
    "default": {
      "expiry": "87600h",
      "usages": [ "signing", "key encipherment", "server auth" ]
    }
  }
}
EOH

# Use the CA certificate to generate the server certificate

cfssl gencert -config ca-config.json -ca ca.pem -ca-key ca-key.pem csr.json | cfssljson -bare server
```

You should now have the following files:

* `ca.csr` and `server.csr`: The certificate signing requests for the CA and the server. Feel free
  to delete these
* `ca-key.pem` and `server-key.pem`: The private keys for the CA and the server.
* `ca.pem` and `server.pem`: The signed public keys for the CA and the server.

### Deploying the tink server

Deploy the tink server:

```hcl
job "tink" {
  datacenters = ["dc1"]
  type = "service"

  group "tink" {
    count = 1

    network {
      port  "grpc"  {
        static = 42113
      }
      port  "http"  {
        static = 42114
      }
    }

    task "apply-migrations" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }
      driver = "docker"
      config {
        image = "quay.io/tinkerbell/tink:latest"
        network_mode = "host"
      }
      env {
        ONLY_MIGRATION = "true"
        PGDATABASE = "tinkerbell"
        PGUSER = "tinkerbell"
        PGPASSWORD = "tinkerbell"
        PGSSLMODE = "disable"
        PGHOST = "localhost"
        PGPORT = "5432"
      }
    }

    task "tink" {
      driver = "docker"
      config {
        image = "quay.io/tinkerbell/tink:latest"
        network_mode = "host"
      }
      env {
        FACILITY = "homelab"
        PGDATABASE = "tinkerbell"
        PGUSER = "tinkerbell"
        PGPASSWORD = "tinkerbell"
        PGSSLMODE = "disable"
        PGHOST = "localhost"
        PGPORT = "5432"

        # expose the grpc and http endpoints on all interfaces
        TINKERBELL_GRPC_AUTHORITY = ":42113"
        TINKERBELL_HTTP_AUTHORITY = ":42114"

        TINKERBELL_CERTS_DIR = "${NOMAD_SECRETS_DIR}/certs/"
      }

      # at the time of writing CERTS_DIR expects this file to contain the ca public key
      template {
        data = file("ca.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/ca-crt.pem"
      }
      template {
        data = file("server-key.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/server-key.pem"
      }
      # at the time of writing CERTS_DIR expects these files to contain the public key
      template {
        data = file("server.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/server-crt.pem"
      }
      template {
        data = file("server.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/bundle.pem"
      }

      resources {
        cpu = 1000
        memory = 512
      }
    }
  }
}
```

Notice that we are forcing migrations to run before the server initialization. This is necessary as
the executable will not run any migrations on boot, despite what the `ONLY_MIGRATION` env-var
implies.

Run the tink server on nomad and verify that it's healthy:

```bash
$ nomad run tink.hcl
$ curl  http://localhost:42114/version
{"git_rev":"unknown","service_name":"tinkerbell"}%
```

## 2. The assets server

The assets server is going to be an nginx server serving the OSIE image via HTTP. Boots will use the
assets server to serve the images.

For the OSIE image, we'll use the alternative image, [hook](https://github.com/tinkerbell/hook/).

This step requires persistence. Let's create a directory to store the images.

```bash
sudo mkdir -p /var/lib/nomad/os_images
```

We'll reuse the `lastmile.sh` scripts provided by the Tinkerbell sandbox.

The script will pick up the latest hook release and extract it, if it's not already in the folder.

The nomad file should look like this

```hcl
job "assets_server" {
  datacenters = ["dc1"]
  type = "service"

  group "assets_server" {
    count = 1

    ephemeral_disk {
      size    = 4000
      migrate = false
      sticky  = false
    }

    network {
      port  "http"  {
        to = 80
        static = 8080
      }
    }

    task "load_osie" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }
      driver = "docker"
      config {
        image = "bash:4.4"
        command = "bash"
        args = [
          "${NOMAD_TASK_DIR}/lastmile.sh",
          "https://github.com/tinkerbell/hook/releases/download/5.10.57/hook_x86_64.tar.gz,https://github.com/tinkerbell/hook/releases/download/5.10.57/hook_aarch64.tar.gz",
          "/usr/share/nginx/html/misc/osie/current",
          "/usr/share/nginx/html/misc/osie/current",
          "/usr/share/nginx/html/workflow",
          "true",
        ]
        mount {
          type = "bind"
          target = "/usr/share/nginx/html/"
          source = "/var/lib/nomad/os_images/"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }
      }
      template {
        data = file("scripts/lastmile.sh")
        destination = "${NOMAD_TASK_DIR}/lastmile.sh"
      }
    }
    task "assets_server" {
      driver = "docker"
      config {
        image = "nginx:1.21.5-alpine"
        network_mode = "bridge"
        mount {
          type = "bind"
          target = "/usr/share/nginx/html/"
          source = "/var/lib/nomad/os_images/"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }
        ports = [
          "http"
        ]
      }
      resources {
        cpu = 1000
        memory = 512
      }
    }
  }
}
```

## 3. The Docker Registry

This is a component that I really wished we could avoid, and supposedly [the documentation states
so](https://docs.tinkerbell.org/services/registry/): *You can use any registry you want: ...A public
one like: Quay or Docker Hub...*

Unfortunately at the date of writing of the guide, the code in the Boots service panics when a registry username/password is not defined. As I don't wish to burden the reader with registering for online services and getting a username/password just so a program's code doesn't crash, we'll deploy a registry.

Rather than following the paradigm of the tinkerbell sandbox and pull actions offline, we will set
up the docker registry as a proxying docker registry and point it to `quay.io` where the images
will need reside.

Save and run the nomad template:

```hcl
variable "registry_host_ip" {
  type = string
  default = "192.168.1.19"
}

job "image_registry" {
  datacenters = ["dc1"]
  type = "service"

  group "image_registry" {
    count = 1

    network {
      port "http" {
        static = 8443
      }
    }

    task "image_registry" {
      driver = "docker"
      config {
        image = "registry:2.7.1"
        network_mode = "host"
        ports = [
          "http"
        ]
      }
      env {
        REGISTRY_HTTP_ADDR = "${var.registry_host_ip}:8443"
        REGISTRY_HTTP_TLS_CERTIFICATE = "${NOMAD_SECRETS_DIR}/certs/server-crt.pem"
        REGISTRY_HTTP_TLS_KEY = "${NOMAD_SECRETS_DIR}/certs/server-key.pem"
        REGISTRY_AUTH = "htpasswd"
        REGISTRY_AUTH_HTPASSWD_REALM = "Registry Realm"
        REGISTRY_AUTH_HTPASSWD_PATH = "${NOMAD_SECRETS_DIR}/htpasswd"
        REGISTRY_PROXY_REMOTEURL = "https://quay.io"
      }
      template {
        data = file("server-key.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/server-key.pem"
      }
      template {
        data = file("server.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/server-crt.pem"
      }
      template {
        # username/password: admin/admin
        data = "admin:$2y$05$kaG7ZpF0X.vSrhcRxee4e.bJUNaZGXOYZsjrrCPhj53INYzrRVJaK"
        destination = "${NOMAD_SECRETS_DIR}/htpasswd"
      }
      resources {
        cpu = 1000
        memory = 512
      }
    }
  }
}
```

## 4. Boots

Let's render the nomadfile:

```hcl
variable "tinkerbell_host_ip" {
  type = string
  default = "192.168.1.19"
}

variable "boots_host_ip" {
  type = string
  default = "192.168.1.19"
}

variable "assets_server_host_ip" {
  type = string
  default = "192.168.1.19"
}

variable "registry_host_ip" {
  type = string
  default = "192.168.1.19"
}

job "boots" {
  datacenters = ["dc1"]
  type = "service"

  group "boots" {
    count = 1

    network {
      port  "dhcp"  {
        static = 67
      }
      port  "tftp"  {
        static = 69
      }
      port "http" {
        static = 80
      }
      port "syslog" {
        static = 514
      }
    }

    task "boots" {
      driver = "docker"
      config {
        image = "quay.io/tinkerbell/boots:latest"
        args = [
          "-dhcp-addr", "0.0.0.0:67",
          "-tftp-addr", "${var.boots_host_ip}:69",
          "-http-addr", "${var.boots_host_ip}:80",
        ]
        cap_add = ["net_bind_service"]
        network_mode = "host"
      }
      env {
        FACILITY_CODE = "homelab"
        MIRROR_HOST = "${var.assets_server_host_ip}:8080"
        DNS_SERVERS = "1.1.1.1"
        PUBLIC_IP = "${var.boots_host_ip}"
        DOCKER_REGISTRY = "${var.registry_host_ip}:8443"
        REGISTRY_USERNAME = "admin"
        REGISTRY_PASSWORD = "admin"
        TINKERBELL_GRPC_AUTHORITY = "${var.tinkerbell_host_ip}:42113"
        TINKERBELL_CERT_URL = "http://${var.tinkerbell_host_ip}:42114/cert"
        DATA_MODEL_VERSION = "1"

        TINKERBELL_CERTS_DIR = "${NOMAD_SECRETS_DIR}/certs/"

        # legacy garbage?
        API_CONSUMER_TOKEN = "ignored"
        API_AUTH_TOKEN = "ignored"
      }

      template {
        data = file("ca.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/ca-crt.pem"
      }
      template {
        data = file("server-key.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/server-key.pem"
      }
      template {
        data = file("server.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/server-crt.pem"
      }
      template {
        data = file("server.pem")
        destination = "${NOMAD_SECRETS_DIR}/certs/bundle.pem"
      }

      resources {
        cpu = 1000
        memory = 512
      }
    }
  }
}
```

Few things to notice for boots:

* it requires the ability to bind privileged ports
* we are using the public registry for the tinkerbell actions. This is probably not great from a
  security perspective (enables a supply chain attack vector in case the vendor gets compromised)

## 5. Hegel

Leaving the most straightforward for last:

```bash
variable "tinkerbell_host_ip" {
  type = string
  default = "192.168.1.19"
}

job "hegel" {
  datacenters = ["dc1"]
  type = "service"

  group "hegel" {
    count = 1

    network {
      port "httpa" {
        static = 50060
      }
      port "httpb" {
        static = 50061
      }
      port "grpc" {
        static = 42115
      }
    }

    task "hegel" {
      driver = "docker"
      config {
        image = "quay.io/tinkerbell/hegel:latest"
        network_mode = "host"
      }
      env {
        GRPC_PORT = "42115"
        HEGEL_FACILITY = "homelab"
        HEGEL_USE_TLS = "0"
        TINKERBELL_GRPC_AUTHORITY = "${var.tinkerbell_host_ip}:42113"
        TINKERBELL_CERT_URL = "http://${var.tinkerbell_host_ip}:42114/cert"
        DATA_MODEL_VERSION = "1"
        CUSTOM_ENDPOINTS = "{\"/metadata\":\"\"}"
      }
      resources {
        cpu = 1000
        memory = 512
      }
    }
  }
}
```

```
nomad run hegel.hcl
```

## 6. Verifying deployment

Open up http://localhost:4646 on your browser and verify that all services have a Status of `running`.

### DHCP Server

Navigate to the logs for tink: Click on the `tink` Job, `tink` Task Group, then on the
allocation ID, then the `tink` task. You should be seeing a **Logs** tab.

Boot your test pc to BIOS. Enable PXE-boot, and set the boot order to network boot with PXE first.

Reboot the test pc and check back to the logs. You should be seeing something like the following:

```
{"level":"info","ts":1641591751.056779,"caller":"dhcp4-go@v0.0.0-20190402165401-39c137f31ad3/handler.go:105","msg":"","service":"github.com/tinkerbell/boots","pkg":"dhcp","pkg":"dhcp","event":"recv","mac":"68:xx:xx:xx:xx:xx","via":"0.0.0.0","iface":"wlp114s0","xid":"\"8c:a7:19:23\"","type":"DHCPDISCOVER","secs":12}
{"level":"info","ts":1641591751.05698,"caller":"boots/dhcp.go:78","msg":"parsed option82/circuitid","service":"github.com/tinkerbell/boots","pkg":"main","mac":"68:xx:xx:xx:xx:xx","circuitID":""}
{"level":"info","ts":1641591751.059148,"caller":"boots/dhcp.go:91","msg":"retrieved job is empty","service":"github.com/tinkerbell/boots","pkg":"main","type":"DHCPDISCOVER","mac":"68:xx:xx:xx:xx:xx","err":"discover from dhcp message: get hardware by mac from tink: rpc error: code = Unknown desc = SELECT: sql: no rows in result set","errVerbose":"rpc error: code = Unknown desc = SELECT: sql: no rows in result set\nget hardware by mac from tink\ngithub.com/tinkerbell/boots/packet.(*client).DiscoverHardwareFromDHCP\n\t/opt/actions-runner/_work/boots/boots/packet/endpoints.go:108\ngithub.com/tinkerbell/boots/job.discoverHardwareFromDHCP.func1\n\t/opt/actions-runner/_work/boots/boots/job/fetch.go:17\ngithub.com/golang/groupcache/singleflight.(*Group).Do\n\t/home/github/go/pkg/mod/github.com/golang/groupcache@v0.0.0-20190702054246-869f871628b6/singleflight/singleflight.go:56\ngithub.com/tinkerbell/boots/job.discoverHardwareFromDHCP\n\t/opt/actions-runner/_work/boots/boots/job/fetch.go:19\ngithub.com/tinkerbell/boots/job.CreateFromDHCP\n\t/opt/actions-runner/_work/boots/boots/job/job.go:111\nmain.dhcpHandler.serveDHCP\n\t/opt/actions-runner/_work/boots/boots/cmd/boots/dhcp.go:89\nmain.dhcpHandler.ServeDHCP.func1\n\t/opt/actions-runner/_work/boots/boots/cmd/boots/dhcp.go:50\ngithub.com/gammazero/workerpool.(*WorkerPool).dispatch.func1\n\t/home/github/go/pkg/mod/github.com/gammazero/workerpool@v0.0.0-20200311205957-7b00833861c6/workerpool.go:169\nruntime.goexit\n\t/opt/actions-runner/_work/_tool/go/1.16.3/x64/src/runtime/asm_amd64.s:1371\ndiscover from dhcp message"}
```

Note the `"mac":"68:xx:xx:xx:xx:xx"` which should correspond to your test pc's MAC address used for
discovering DHCP.

Boots doesn't perform any actions as there are no actions to perform for this hardware.
Let's register the hardware.

### Workflows

Time to set up `tink`. The CLI is configured using environment variables:

```bash
export TINKERBELL_GRPC_AUTHORITY=192.168.1.19:42113
export TINKERBELL_CERT_URL=http://192.168.1.19:42114/cert
```

```bash
# Let's prepare registering our device to tink
export FACILITY=homelab
cat <<EOH > hardware.json
{
  "id": "$(uuidgen)",
  "metadata": {
    "facility": {
      "facility_code": "$FACILITY",
      "plan_slug": "j4125",
      "plan_version_slug": ""
    },
    "instance": {},
    "state": "provisioning"
  },
  "network": {
    "interfaces": [
      {
        "dhcp": {
          "arch": "x86_64",
          "ip": {
            "address": "192.168.1.55",
            "netmask": "255.255.255.0"
          },
          "mac": "68:xx:xx:xx:xx:xx",
          "uefi": true
        },
        "netboot": {
          "allow_pxe": true,
          "allow_workflow": true
        }
      }
    ]
  }
}
EOH
```

Then, execute:

```bash
tink hardware push --file hardware.json
2022/01/08 21:37:53 Hardware data pushed successfully
```

Turning the test pc on now will boot it into the `hook` OSIE, without any further actions.

Next, add a template:

```bash
# Let's prepare registering our device to tink
export FACILITY=homelab
cat <<EOH > template.json
EOH
```

And, that's it! On next boot the test pc should provision with the template!
