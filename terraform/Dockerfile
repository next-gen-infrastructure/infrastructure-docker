#################################################################################
# Inspired by
# https://github.com/cloudbees/java-build-tools-dockerfile/blob/master/Dockerfile
#################################################################################
ARG ALPINE_VERSION=3.18
ARG PYTHON_VERSION=3.9.18
FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION} as awscli

ARG AWS_CLI_VERSION=2.15.28
RUN \
  apk add --no-cache \
    build-base \
    cmake \
    git \
    groff \
    libffi-dev \
    unzip \
  && git clone --single-branch --depth 1 -b ${AWS_CLI_VERSION} https://github.com/aws/aws-cli.git \
  && cd aws-cli \
  && python -m venv venv \
  && . venv/bin/activate \
  && scripts/installers/make-exe \
  && unzip -q dist/awscli-exe.zip \
  && aws/install --bin-dir /aws-cli-bin \
  && /aws-cli-bin/aws --version \
  && rm -rf \
    /usr/local/aws-cli/v2/current/dist/aws_completer \
    /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
    /usr/local/aws-cli/v2/current/dist/awscli/examples \
  && find /usr/local/aws-cli/v2/current/dist/awscli/data -name 'completions-1*.json' -delete \
  && find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete


FROM alpine:${ALPINE_VERSION} as main

ENV LANG=C.UTF-8 \
    PROFILE="~/.bashrc"

RUN \
  apk add --no-cache \
    bash \
    curl \
    git \
    git-crypt \
    gnupg \
    jq \
    python3 \
    py3-pip \
    shadow \
    openssh \
    openssh-client \
    unzip \
    wget \
  && pip3 install  --no-cache-dir -U \
    ansible \
    hvac \
    pip \
    yq \
    wheel \
  && rm -rf /var/cache/apk/*

#=======================================
# AWS Cli
#=======================================
COPY --from=awscli /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=awscli /aws-cli-bin/ /usr/local/bin/

#=======================================
# Terraform install
#=======================================
ARG TERRAFORM_VERSION=1.8.2
ENV TERRAFORM_VERSION=$TERRAFORM_VERSION
RUN wget --quiet -O /tmp/terraform.zip \
    "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
  && unzip -p /tmp/terraform.zip terraform > /tmp/terraform \
  && chmod +x /tmp/terraform \
  && mv /tmp/terraform /usr/bin/terraform \
  && ln -s /usr/bin/terraform "/usr/bin/terraform${TERRAFORM_VERSION}" \
  && rm -rf /tmp/terraform.zip

#=======================================
# Terragrunt install
#=======================================
ENV TERRAGRUNT_VERSION=0.57.8
RUN wget --quiet -O /tmp/terragrunt \
    "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" \
  && chmod +x /tmp/terragrunt \
  && mv /tmp/terragrunt /usr/bin/terragrunt

#=======================================
# Terraform providers cache
#=======================================
ENV TF_PLUGIN_CACHE_DIR="/usr/share/terraform/providers"
COPY terragrunt-core.hcl ${TF_PLUGIN_CACHE_DIR}/../
COPY install-providers.sh "/tmp/install-providers.sh"
COPY providers.txt "/tmp/providers.txt"
COPY terraform.rc "/root/.terraformrc"
RUN /tmp/install-providers.sh "/tmp/providers.txt"

# GOLANG support
COPY --from=golang:1.19-alpine /usr/local/go/ /usr/local/go/
ENV PATH="/usr/local/go/bin:${PATH}"

#=======================================
# Known Hosts authentication
#=======================================
RUN mkdir -p ~/.ssh > /dev/null \
   && ssh-keyscan "github.com" >> ~/.ssh/known_hosts 2> /dev/null

#=======================================
# Validate installation
#=======================================
RUN \
  terraform --version \
  && terragrunt --version \
  && yq --version \
  && aws --version \
  && go version
CMD [ "bash" ]
