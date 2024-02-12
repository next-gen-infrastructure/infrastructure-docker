ARG ATLANTIS_VERSION=v0.27.1
FROM node:16 as node

# Build dependencies
RUN \
    yarn global add inkdrop-visualizer pkg

WORKDIR /usr/src/app

RUN \
  pkg -o inkdrop "$(which inkdrop)"

FROM ghcr.io/runatlantis/atlantis:${ATLANTIS_VERSION} AS tools
USER root
ARG GOSU_VERSION=1.17
RUN \
    wget -q \
      "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64" \
      -O /usr/local/bin/gosu && \
    chmod +x /usr/local/bin/gosu

# Install infracost
ARG INFRACOST_VERSION=v0.10.32
RUN \
    wget -q \
      "https://github.com/infracost/infracost/releases/download/${INFRACOST_VERSION}/infracost-linux-amd64.tar.gz" \
      -O infracost-linux-amd64.tar.gz && \
    tar xzf infracost-linux-amd64.tar.gz && \
    mv infracost-linux-amd64 /usr/local/bin/infracost && \
    rm -f infracost-linux-amd64.tar.gz

USER atlantis

# Install Atlantis
FROM ghcr.io/next-gen-infrastructure/terraform-ci:latest

RUN \
    addgroup atlantis && \
    adduser -S atlantis -G atlantis && \
    cp /root/.terraformrc /home/atlantis/

ENV TF_PLUGIN_CACHE_DIR="/usr/share/terraform/providers"
ENV ATLANTIS_TERRAFORM_VERSION=${TERRAFORM_VERSION}
ENV DEFAULT_TERRAFORM_VERSION=$TERRAFORM_VERSION
ENV TERRAGRUNT_TFPATH="terraform${TERRAFORM_VERSION}"
ENV TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE=true
ENV DEFAULT_CONFTEST_VERSION=0.35.0

COPY atlantis-config.yaml /etc/atlantis/repos.yaml

COPY --from=tools /usr/local/bin/gosu /usr/local/bin/gosu
COPY --from=tools /usr/local/bin/atlantis /usr/local/bin/atlantis
COPY --from=tools /usr/bin/dumb-init /usr/local/bin/dumb-init
COPY --from=tools /usr/local/bin/conftest /usr/local/bin/conftest
COPY --from=tools /usr/local/bin/infracost /usr/local/bin/infracost

COPY --from=node /usr/src/app/inkdrop /usr/local/bin/inkdrop

COPY --from=tools /usr/bin/dumb-init /usr/bin/dumb-init
COPY --from=tools /usr/local/bin/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

RUN \
   atlantis version \
   && infracost --version \
   && inkdrop --version
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["server"]
