#!/bin/sh

set -e

certbot certonly --non-interactive --dns-cloudflare --dns-cloudflare-propagation-seconds 120 --dns-cloudflare-credentials "$CF_CREDS_PATH" -d "*.$SSL_DOMAIN" -d "$SSL_DOMAIN" -m "$CONTACT_EMAIL" --agree-tos

for KEY in cert chain fullchain privkey; do
    cat "/etc/letsencrypt/live/$SSL_DOMAIN/$KEY.pem" | consul kv put "ssl/$SSL_DOMAIN/$KEY" -
done


vault kv put -mount=kv nomad/shared/generated/ssl/$SSL_DOMAIN \
  cert="@/etc/letsencrypt/live/$SSL_DOMAIN/cert.pem" \
  chain="@/etc/letsencrypt/live/$SSL_DOMAIN/chain.pem" \
  fullchain="@/etc/letsencrypt/live/$SSL_DOMAIN/fullchain.pem" \
  privkey="@/etc/letsencrypt/live/$SSL_DOMAIN/privkey.pem"
