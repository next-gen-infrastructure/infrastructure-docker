ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

FROM --platform=${BUILDPLATFORM:-linux/amd64} ghcr.io/actions-runner-controller/actions-runner-controller/actions-runner-dind:ubuntu-22.04

USER root

ARG KUBECTL_VERSION=1.30.1
RUN \
    curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

ARG AWS_CLI_VERSION=2.15.61
RUN \
  if [ "${TARGETARCH}" = "arm64" ]; then export TARGETARCH="aarch64"; else export TARGETARCH="x86_64"; fi \
  && curl "https://awscli.amazonaws.com/awscli-exe-linux-${TARGETARCH}-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm -rf \
    /usr/local/aws-cli/v2/current/dist/aws_completer \
    /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
    /usr/local/aws-cli/v2/current/dist/awscli/examples \
  && find /usr/local/aws-cli/v2/current/dist/awscli/data -name 'completions-1*.json' -delete \
  && find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete

USER runner

RUN \
  uname -m \
  && aws --version \
  && cat /usr/local/bin/kubectl \
  && kubectl version --client
