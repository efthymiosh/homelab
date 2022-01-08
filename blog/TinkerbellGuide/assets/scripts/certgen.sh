#!/bin/bash

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
