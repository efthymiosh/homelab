FROM certbot/dns-cloudflare:latest

ARG CONSUL_VERSION=1.20.1
ARG VAULT_VERSION=1.18.2

RUN wget -O /tmp/consul.zip https://releases.hashicorp.com/consul/$CONSUL_VERSION/consul_${CONSUL_VERSION}_linux_amd64.zip && \
    unzip /tmp/consul.zip -x LICENSE.txt -d /bin && \
    rm /tmp/consul.zip

RUN wget -O /tmp/vault.zip https://releases.hashicorp.com/vault/$VAULT_VERSION/vault_${VAULT_VERSION}_linux_amd64.zip && \
    unzip /tmp/vault.zip -x LICENSE.txt -d /bin && \
    rm /tmp/vault.zip

COPY entrypoint.sh /bin/entrypoint.sh

ENTRYPOINT ["/bin/entrypoint.sh"]
