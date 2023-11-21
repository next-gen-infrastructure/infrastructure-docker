# Terragrunt execution Agent

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [AWS SSO configuration](#aws-sso-configuration)
- [Usage](#usage)
  - [Examples](#examples)
  - [Arguments](#arguments)
  - [Exit codes](#exit-codes)
- [Docker components](#docker-components)

## Overview
The script builds stack using terraform modules repositories.

## Prerequisites
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [Docker](https://docs.docker.com/get-docker/)
- [git-crypt](https://github.com/AGWA/git-crypt)
- [jq](https://stedolan.github.io/jq/)
- [aws-sso-credential-process](https://pypi.org/project/aws-sso-credential-process/)

## AWS SSO configuration
Prepare AWS profiles for SSO authentication
```
[profile org]
sso_start_url = https://cere.awsapps.com/start
sso_region = us-west-2
sso_account_id = 524725240689
sso_role_name = AdministratorAccess
region = us-west-2
output = json
```
## Usage
#### Examples
Build plan of ecs/example-service stack in idt_dev AWS account.
Region and environment will be detected automatically.
```shell
terragrunt-test -a cere-sandbox -s ecs/example-service
```

List resources in terraform state for _ecs/example-service_ stack in _cere-sandbox_ AWS account,
_us-west-2_ region within _dev_ environment. Debug information will be shown.
```shell
terragrunt-test --debug \
  --account cere-sandbox \
  --region us-west-2 \
  --environment dev \
  --stack ecs/example-service \
  --command 'state list'
```

#### Arguments
* **-a**, **--account** (string): Required parameter. Account to plan.
  Defined by location in _aws/_ folder.
* **-r**, **--region** (string): Optional parameter. Region to plan.
  Defined by location in _aws/**account name**/_ folder.
* **-e**, **--environment** (string): Optional parameter. Environment to plan.
  Defined by location in _aws/**account name**/**region**/_ folder.
* **-s**, **--stack** (string): Optional parameter. Opt-out to plan single stack instead of whole environment.
  Defined by location of `terragrunt.hcl` pointing to module.

* **-c**, **--command** (string): Optional parameter. Execute custom terragrunt command.
  If stack is not provided adds `run-all` command. Defaults to `plan`.
* **-d**, **--destroy** (boolean): Optional parameter.
  If `terraform plan` is executing to destroy resources. Defaults false.

* **-v**, **--debug** (boolean):  Output debug error log. Defaults false.
* **-t**, **--terraform-version** (string):  Optional parameter. Select version of terraform image to use. Defaults to `latest`.

* **--path** (string):  Optional parameter. Location of the _*-terra-live_ repository.
  Defaults to current working directory.
* **--modules-path** (string):  Optional parameter. Location of the _*-terraform-modules_ repository.
  Defaults to current working directory.

#### Exit codes

* **0**: If successful.
* **1**: Generic error.
* **2**: Missing arguments.
* **3**: Path not found.
* **4**: Missing prerequisite software.
* **5**: Authentication failure.

## Docker components
- [Terraform](https://github.com/hashicorp/terraform/releases)
- [Terragrunt](https://github.com/gruntwork-io/terragrunt/releases)
- Terraform Providers:
  - [archive](https://github.com/hashicorp/terraform-provider-archive/tags)
  - [aws](https://github.com/hashicorp/terraform-provider-aws/releases)
  - [cloudinit](https://github.com/hashicorp/terraform-provider-cloudinit/tags)
  - [external](https://github.com/hashicorp/terraform-provider-external/releases)
  - [grafana](https://github.com/grafana/terraform-provider-grafana/releases)
  - [helm](https://github.com/hashicorp/terraform-provider-helm/releases)
  - [http](https://github.com/hashicorp/terraform-provider-http/releases)
  - [htpasswd](https://github.com/loafoe/terraform-provider-htpasswd/releases)
  - [kubernetes](https://github.com/hashicorp/terraform-provider-kubernetes/releases)
  - [local](https://github.com/hashicorp/terraform-provider-local/releases)
  - [null](https://github.com/hashicorp/terraform-provider-null/releases)
  - [random](https://github.com/hashicorp/terraform-provider-random/releases)
  - [time](https://github.com/hashicorp/terraform-provider-time/releases)
  - [tls](https://github.com/hashicorp/terraform-provider-tls/releases)
  - [vault](https://github.com/hashicorp/terraform-provider-vault/releases)

# Update provider versions
You can check new versions of the providers and make decision to upgrade them:

`./install-providers.sh <file containing list of terraform providers> <if the providers be installed locally>`

For Example:

`./install-providers.sh providers.txt false`
