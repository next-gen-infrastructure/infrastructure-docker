FROM ghcr.io/actions-runner-controller/actions-runner-controller/actions-runner-dind:ubuntu-22.04

USER root

ARG AWS_CLI_VERSION=2.15.28
RUN \
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm -rf \
    /usr/local/aws-cli/v2/current/dist/aws_completer \
    /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
    /usr/local/aws-cli/v2/current/dist/awscli/examples \
  && find /usr/local/aws-cli/v2/current/dist/awscli/data -name 'completions-1*.json' -delete \
  && find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete

ARG KUBECTL_VERSION=1.29.2
RUN \
    curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

USER runner

RUN \
  aws --version \
  && kubectl version
