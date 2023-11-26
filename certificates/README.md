# Certificate generation

## Root CA

Generate self-signed:

```bash
cfssl gencert -initca root-csr.json | cfssljson -bare root-ca
```

## Intermediate CA

Generate key:

```bash
cfssl genkey intermediate-csr.json | cfssljson -bare intermediate-ca
```

Sign with root:

```bash
cfssl sign -ca root-ca.pem -ca-key root-ca-key.pem -config config.json -profile intermediate intermediate-ca.csr \
| cfssljson -bare intermediate-ca
```

## Server

Generate signed certificate:

```bash
cfssl gencert \
    -ca intermediate-ca.pem \
    -ca-key intermediate-ca-key.pem \
    -config config.json \
    -profile server \
    vault-csr.json \
| cfssljson -bare vault
```

Bundle:

```bash
cat vault.pem intermediate-ca.pem > vault-fullchain.pem
```
