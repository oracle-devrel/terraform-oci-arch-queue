## Copyright (c) 2022, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# Create VCN

resource "oci_core_virtual_network" "vcn" {
  cidr_block     = var.VCN-CIDR
  compartment_id = var.compartment_ocid
  display_name   = "queue_vcn_${random_id.tag.hex}"
  defined_tags   = {}
}

# Create internet gateway to allow public internet traffic

resource "oci_core_internet_gateway" "application_internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.app_name}_app_internet_gateway_${random_id.tag.hex}"
  vcn_id         = oci_core_virtual_network.vcn.id
  defined_tags   = {}
}

# Create service gateway for OCI service access
resource "oci_core_service_gateway" "application_service_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.app_name}_app_servicegateway_${random_id.tag.hex}"
  vcn_id         = oci_core_virtual_network.vcn.id
  services {
    service_id = lookup(data.oci_core_services.all_services.services[0], "id")
  }
  defined_tags = { }

}

resource "oci_core_nat_gateway" "application_nat_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.app_name}_app_natgateway_${random_id.tag.hex}"
  vcn_id         = oci_core_virtual_network.vcn.id
  defined_tags   = {}
}

# Create route tables to connect vcn to internet gateway

resource "oci_core_route_table" "application_private_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "vcn_route_table_${random_id.tag.hex}"

  route_rules {
    description       = "Traffic to the internet"
    destination       = lookup(var.application_network_cidrs, "ALL-CIDR")
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.application_nat_gateway.id
  }
  route_rules {
    description       = "Traffic to OCI services"
    destination       = lookup(data.oci_core_services.all_services.services[0], "cidr_block")
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.application_service_gateway.id
  }
  defined_tags = {}
}

resource "oci_core_route_table" "application_public_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "function_rt_${random_id.tag.hex}"

  route_rules {
    description       = "Traffic to/from internet"
    destination       = lookup(var.application_network_cidrs, "ALL-CIDR")
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.application_internet_gateway.id
  }
  defined_tags = {}

}



# Create security list to allow internet access from compute and ssh access

resource "oci_core_security_list" "sl" {
  compartment_id = var.compartment_ocid
  display_name   = "security-list"
  vcn_id         = oci_core_virtual_network.vcn.id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }

  ingress_security_rules {

    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = 22
      min = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = 80
      min = 80
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = 443
      min = 443
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "10.100.0.0/16"

    tcp_options {
      max = 3306
      min = 3306
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "10.0.0.0/16"

    tcp_options {
      max = 3306
      min = 3306
    }
  }

  ingress_security_rules {
    protocol = "1"
    source   = "10.0.0.0/16"

  }


  defined_tags = {}
}

# Create regional subnets in vcn

resource "oci_core_subnet" "application_public_subnet" {
  cidr_block        = var.Public-Subnet-CIDR
  display_name      = "PublicSubnet-Application-VCN"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.vcn.id
  dhcp_options_id   = oci_core_virtual_network.vcn.default_dhcp_options_id
  route_table_id    = oci_core_route_table.application_public_route_table.id
  security_list_ids = [oci_core_security_list.sl.id]

  provisioner "local-exec" {
    command = "sleep 5"
  }

  defined_tags = {}
}

resource "oci_core_subnet" "application_private_subnet" {
  cidr_block                 = var.Private-Subnet-CIDR
  display_name               = "PrivateSubnet-Application-VCN"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.vcn.id
  dhcp_options_id            = oci_core_virtual_network.vcn.default_dhcp_options_id
  route_table_id             = oci_core_route_table.application_private_route_table.id
  security_list_ids          = [oci_core_security_list.sl.id]
  prohibit_public_ip_on_vnic = true
  provisioner "local-exec" {
    command = "sleep 5"
  }

  defined_tags = {}
}

resource "oci_core_local_peering_gateway" "test_local_peering_gateway_2" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "Local peering to OKE VCN"
  defined_tags   = {}
}

