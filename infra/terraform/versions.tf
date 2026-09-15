terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Local state — single-operator setup, same as chatelaine/infra/terraform.
  # Separate state file/directory from the family product on purpose: this
  # app's infra should be destroyable/inspectable without touching theirs.
}
