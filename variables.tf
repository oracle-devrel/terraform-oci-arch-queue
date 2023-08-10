## Copyright (c) 2020, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
variable "current_user_ocid" {}
variable "fingerprint" {
  type = string
  default = "TODO"
}
variable "private_key_path" {
  type = string
  default = "TODO"
}
variable "compartment_ocid" {}
variable "region" {default = "us-ashburn-1"}
variable "home_region" { default = ""}
variable "ocir_user_name" {}
variable "ocir_user_password" {}
variable "queue_display_name" {
  default = "demo_queue"
}

variable "path_prefix" {
  default = "/"
}
variable "consumer_route_path" {
  default = "queuelength"
}
variable "app_name" {
  default     = "queuedemoapp"
  description = "Application name. Will be used as prefix to identify resources, such as OKE, VCN, DevOps, and others"
}


variable "fnsubnet-CIDR" {
  default = "10.0.1.0/24"
}

variable "ocir_repo_name" {
  default = "container_repo"
}
variable network_cidrs{

  default = ""
}

/********** VCN Variables **********/
variable "VCN-CIDR" {
  default = "10.100.0.0/16"
}

variable "Public-Subnet-CIDR" {
  default = "10.100.0.0/24"
}


variable "Private-Subnet-CIDR" {
  default = "10.100.10.0/24"
}

variable "application_network_cidrs" {
  type = map(string)

  default = {
    VCN-CIDR                      = "10.100.0.0/16"
    PRIVATE-SUBNET-CIDR           = "10.100.10.0/24"
    PUBLIC-SUBNET-CIDR            = "10.100.0.0/24"
    ALL-CIDR                      = "0.0.0.0/0"

  }
}


/********** VCN Variables **********/



variable "node_pool_instance_shape_1" {
  type = map(any)
  default = {
    "instanceShape" = "VM.Standard.E4.Flex"
    "ocpus"         = 4
    "memory"        = 64
  }
  description = "Default Node Pool: A shape is a template that determines the number of OCPUs, amount of memory, and other resources allocated to a newly created instance for the Worker Node. Select at least 2 OCPUs and 16GB of memory if using Flex shapes"
}
variable "k8s_version" {
  default     = "Latest"
  description = "Kubernetes version installed on your Control Plane and worker nodes. If not version select, will use the latest available."
}
variable "vcn_cidr_blocks" {
  default     = "10.26.0.0/16"
  description = "IPv4 CIDR Blocks for the Virtual Cloud Network (VCN). If use more than one block, separate them with comma. e.g.: 10.20.0.0/16,10.80.0.0/16. If you plan to peer this VCN with another VCN, the VCNs must not have overlapping CIDRs."
}

variable "oke_namespace" {
  default = "svc"
}

variable "oke_keda_namespace" {
  default = "keda"
}

data "oci_identity_regions" "oci_regions" {

  filter {
    name   = "name"
    values = [var.region]
  }

}

# OCI Services
## Available Services
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}
data "oci_containerengine_cluster_option" "oke" {
  cluster_option_id = "all"
}
data "oci_containerengine_node_pool_option" "oke" {
  node_pool_option_id = "all"
}

# OCIR repo name & namespace

locals {
  ocir_docker_repository = join("", [lower(lookup(data.oci_identity_regions.oci_regions.regions[0], "key")), ".ocir.io"])
  ocir_namespace         = data.oci_identity_tenancy.current_user_tenancy.name
}
