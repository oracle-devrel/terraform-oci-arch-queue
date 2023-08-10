## Copyright (c) 2020, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_identity_dynamic_group" "dg_queues" {
  provider       = oci.home_region
  name           = "queue_dg_tf_${random_id.tag.hex}"
  description    = "dynamic group for queue demo"
  compartment_id = var.tenancy_ocid
  matching_rule  = "Any {All {instance.compartment.id = '${var.compartment_ocid}'},ALL {resource.type = 'fnfunc',resource.compartment.id = '${var.compartment_ocid}'},ALL {resource.type = 'ApiGateway', resource.compartment.id = '${var.compartment_ocid}'}}"
}

resource "oci_identity_policy" "queue_demo_policies" {
  
  provider       = oci.home_region
  compartment_id = var.compartment_ocid
  name           = "Queue_demo_policies_${random_id.tag.hex}"
  
  description    = "Policy to provide access to use queue , fn invoke "
  statements = [

    "allow dynamic-group ${oci_identity_dynamic_group.dg_queues.name} to use queues in compartment id ${var.compartment_ocid}",

    "allow dynamic-group ${oci_identity_dynamic_group.dg_queues.name} to use fn-invocation in compartment id ${var.compartment_ocid}",
	
	"Allow dynamic-group ${oci_identity_dynamic_group.dg_queues.name} to manage repos in compartment id ${var.compartment_ocid}"
	
	



  ]
}
