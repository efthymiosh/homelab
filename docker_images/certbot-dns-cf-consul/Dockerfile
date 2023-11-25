FROM certbot/dns-cloudflare:latest

ARG CONSUL_VERSION=1.16.2

RUN wget -O /tmp/consul.zip https://releases.hashicorp.com/consul/$CONSUL_VERSION/consul_${CONSUL_VERSION}_linux_amd64.zip && \
    unzip /tmp/consul.zip -d /bin && \
    rm /tmp/consul.zip

COPY entrypoint.sh /bin/entrypoint.sh

ENTRYPOINT /bin/entrypoint.sh
