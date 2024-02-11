FROM certbot/dns-cloudflare:latest

ARG CONSUL_VERSION=1.16.2
ARG VAULT_VERSION=1.15.5

RUN wget -O /tmp/consul.zip https://releases.hashicorp.com/consul/$CONSUL_VERSION/consul_${CONSUL_VERSION}_linux_amd64.zip && \
    unzip /tmp/consul.zip -d /bin && \
    rm /tmp/consul.zip

RUN wget -O /tmp/vault.zip https://releases.hashicorp.com/vault/$VAULT_VERSION/vault_${VAULT_VERSION}_linux_amd64.zip && \
    unzip /tmp/vault.zip -d /bin && \
    rm /tmp/vault.zip

COPY entrypoint.sh /bin/entrypoint.sh

ENTRYPOINT /bin/entrypoint.sh
