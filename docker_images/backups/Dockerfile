FROM debian:bookworm

ARG CONSUL_VERSION=1.16.2

RUN wget -O /tmp/consul.zip https://releases.hashicorp.com/consul/$CONSUL_VERSION/consul_${CONSUL_VERSION}_linux_amd64.zip && \
    unzip /tmp/consul.zip -d /bin && \
    rm /tmp/consul.zip && \
    apt update && \
    apt install -fyq awscli postgres-client && \
    apt autoremove -fyq


ENTRYPOINT /bin/bash
