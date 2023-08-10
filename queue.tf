## Copyright (c) 2020, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_queue_queue" "test_queue" {
  #Required
  compartment_id = var.compartment_ocid
  display_name   = "${var.queue_display_name}_${random_id.tag.hex}"

  #Optional
  # custom_encryption_key_id = oci_kms_key.test_key.id
  # dead_letter_queue_delivery_count = var.queue_dead_letter_queue_delivery_count
  # defined_tags = {"foo-namespace.bar-key"= "value"}
  # freeform_tags = {"bar-key"= "value"}
  # retention_in_seconds = var.queue_retention_in_seconds
  # timeout_in_seconds = var.queue_timeout_in_seconds
  # visibility_in_seconds = var.queue_visibility_in_seconds
}