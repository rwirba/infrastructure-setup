FROM ubuntu:22.04

RUN apt-get update && apt-get install -y unzip curl jq

ENV VAULT_VERSION=1.15.0

RUN curl -fsSL https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -o vault.zip && \
    unzip vault.zip && mv vault /usr/local/bin/ && chmod +x /usr/local/bin/vault

CMD ["vault", "server", "-dev"]
