FROM ghcr.io/actions-runner-controller/actions-runner-controller/actions-runner-dind:ubuntu-22.04

USER root

RUN apt-get update \
     && apt-get install -y --no-install-recommends \
        kubectl=1.30.1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG AWS_CLI_VERSION=2.15.61
RUN \
  if [ "$(uname -m)" = "arm64" ]; then export TARGETARCH="aarch64"; else export TARGETARCH="x86_64"; fi \
  && curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-${TARGETARCH}-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" \
  && unzip -qq awscliv2.zip \
  && ./aws/install > /dev/null \
  && rm -rf \
    /usr/local/aws-cli/v2/current/dist/aws_completer \
    /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
    /usr/local/aws-cli/v2/current/dist/awscli/examples \
  && find /usr/local/aws-cli/v2/current/dist/awscli/data -name 'completions-1*.json' -delete \
  && find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete

USER runner

RUN \
  aws --version # \
  # && kubectl version --client
