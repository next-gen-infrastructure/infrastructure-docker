locals {
  # Automatically load global-level variables
  global_vars = read_terragrunt_config(
    find_in_parent_folders(
      ".global.hcl",
      "fallback.hcl",
    )
  )

  master_account_id   = local.global_vars.locals.backend.account_id
  backend_bucket      = local.global_vars.locals.backend.bucket
  backend_region      = local.global_vars.locals.backend.region
  backend_locks_table = local.global_vars.locals.backend.locks_table

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(
    find_in_parent_folders(
      ".account.hcl",
      "fallback.hcl",
    )
  )

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(
    find_in_parent_folders(
      ".region.hcl",
      "fallback.hcl",
    ),
    {
      locals = {
        region = local.backend_region
      }
    }
  )

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(
    find_in_parent_folders(
      ".env.hcl",
      "fallback.hcl",
    ),
    {
      locals = {
        env = "dev"
      }
    }
  )

  # Extract the variables we need for easy access
  infrastructure_repository = local.global_vars.locals.infrastructure_repository
  provider                  = split("/", path_relative_to_include())[0]
  account_configuration = {
    name   = local.account_vars.locals.account_name
    id     = local.account_vars.locals.account_id
    region = local.region_vars.locals.region
  }

  env_name = local.environment_vars.locals.env
  environment_path = join(
    "/",
    [
      local.provider,
      local.account_configuration.name
    ]
  )
  stack_path = replace(path_relative_to_include(), local.environment_path, "")

  entry_point_role = "arn:aws:iam::${local.master_account_id}:role/terraform-management"

  terragrunt_config_path = "${get_terragrunt_dir()}/terragrunt.hcl"
  terragrunt_stack_name = element(
    regex(
      ".*stack_name\\s+=\\s+\"([^\"]+)\"",
      run_cmd(
        "--terragrunt-quiet",
        "grep", "stack_name ", local.terragrunt_config_path
      )
    ), 0
  )

  terragrunt_stack_version = element(
    regex(
      ".*stack_version\\s+=\\s+\"([^\"]+)\"",
      run_cmd(
        "--terragrunt-quiet",
        "grep", "stack_version ", local.terragrunt_config_path
      )
    ), 0
  )
  terragrunt_module_name = join(
    " ",
    [
      local.terragrunt_stack_name,
      local.terragrunt_stack_version
    ]
  )
  full_configuration = merge(
    local.global_vars.locals,
    local.account_vars.locals,
    local.region_vars.locals,
    local.environment_vars.locals,
    {
      terragrunt_config = {
        stack_name    = local.terragrunt_stack_name
        stack_version = local.terragrunt_stack_version
      }
    }
  )
}

# Entry-point for terraform executions
iam_role = local.entry_point_role

terraform {
  extra_arguments "retry_lock" {
    commands = get_terraform_commands_that_need_locking()
    arguments = [
      "-lock-timeout=1m"
    ]
  }

  extra_arguments "init_upgrade" {
    commands = [
      "init"
    ]
    arguments = [
      "-upgrade"
    ]
  }

  extra_arguments "unlock_plan" {
    commands = [
      "plan"
    ]
    arguments = [
      "-lock=false"
    ]
  }

  extra_arguments "conditional_vars" {
    commands = get_terraform_commands_that_need_vars()

    optional_var_files = [
      "${get_terragrunt_dir()}/terraform.tfvars",
      "${get_terragrunt_dir()}/secrets.auto.tfvars",
    ]
  }
}

# Generate an AWS provider block
generate "provider" {
  path      = "aws-provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
%{if "${local.provider}" == "aws"}
provider "aws" {
  region = "${local.account_configuration.region}"

  assume_role {
    role_arn     = "arn:aws:iam::${local.account_configuration.id}:role/terraform"
    session_name = "terraform"
  }

  default_tags {
    tags = {
      "environment_name"            = "${local.env_name}"
      "product"                     = "${local.full_configuration.product_name}"
      "devops:automation"           = "terraform"
      "devops:infrastructure_repo"  = "${local.infrastructure_repository}"
      "devops:terraform_module"     = "${local.terragrunt_module_name}"
    }
  }

  ignore_tags {
    key_prefixes = [
      "kubernetes.io/cluster/"
    ]
  }

  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
}
%{endif}

terraform {
  backend "s3" {}
}
EOF
}

remote_state {
  backend = "s3"

  config = {
    encrypt        = true
    bucket         = local.backend_bucket
    key            = "${local.infrastructure_repository}/${path_relative_to_include()}/terraform.tfstate"
    region         = local.backend_region
    encrypt        = true
    dynamodb_table = local.backend_locks_table

    disable_bucket_update       = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this sub-folder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

# Configure root level variables that all resources can inherit. This is especially helpful with multi-account configs
# where terraform_remote_state data sources are placed directly into the modules.
inputs = {
  default_variables = local.full_configuration
}
