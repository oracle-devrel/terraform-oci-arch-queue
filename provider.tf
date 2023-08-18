## Copyright (c) 2020, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl


terraform {
  required_version = ">= 1.1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 4, < 5"
      # https://registry.terraform.io/providers/oracle/oci/
      configuration_aliases = [oci.home_region]
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.current_user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# provider "oci" {
#   alias                = "homeregion"
#   tenancy_ocid         = var.tenancy_ocid
#   user_ocid            = var.current_user_ocid
#   fingerprint          = var.fingerprint
#   private_key_path     = var.private_key_path
#   region               = data.oci_identity_region_subscriptions.home_region_subscriptions.region_subscriptions[0].region_name
#   disable_auto_retries = "true"
# }

provider "oci" {
  alias        = "home_region"
  tenancy_ocid = var.tenancy_ocid
  region       = local.home_region

  user_ocid        = var.current_user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}



data "oci_identity_region_subscriptions" "home_region_subscriptions" {
  tenancy_id = var.tenancy_ocid

  filter {
    name   = "is_home_region"
    values = [true]
  }
}
data "oci_identity_user" "current_user" {
  provider = oci.home_region
  user_id  = var.current_user_ocid
}

data "oci_identity_tenancy" "current_user_tenancy" {
  provider   = oci.home_region
  tenancy_id = var.tenancy_ocid
}

# Gets home and current regions
data "oci_identity_tenancy" "tenant_details" {
  tenancy_id = var.tenancy_ocid
}
data "oci_identity_regions" "home_region" {
  filter {
    name   = "key"
    values = [data.oci_identity_tenancy.tenant_details.home_region_key]
  }

  count = var.home_region != "" ? 0 : 1
}
locals {
  home_region = var.home_region != "" ? var.home_region : lookup(data.oci_identity_regions.home_region.0.regions.0, "name")
}