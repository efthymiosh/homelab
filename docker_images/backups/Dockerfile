FROM postgres:16-bookworm

ARG CONSUL_VERSION=1.20.1

RUN apt update && \
    apt install -fyq wget unzip awscli postgresql-client && \
     wget -q -O /tmp/consul.zip https://releases.hashicorp.com/consul/$CONSUL_VERSION/consul_${CONSUL_VERSION}_linux_amd64.zip && \
    unzip /tmp/consul.zip -x LICENSE.txt -d /bin && \
    apt remove -fyq wget unzip && \
    apt autoremove -fyq && \
    rm -rf /var/lib/apt/lists/* /tmp/consul.zip


ENTRYPOINT ["/bin/bash"]
