## Copyright (c) 2022, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_apigateway_gateway" "api_gateway" {
  compartment_id             = var.compartment_ocid
  defined_tags               = {}
  display_name               = "${var.app_name}_api_gateway_${random_id.tag.hex}"
  endpoint_type              = "PUBLIC"
  freeform_tags              = {}
  network_security_group_ids = []
  subnet_id                  = oci_core_subnet.application_public_subnet.id
  

  response_cache_details {
    connect_timeout_in_ms  = 0
    is_ssl_enabled         = false
    is_ssl_verify_disabled = false

    type = "NONE"
  }

  timeouts {}
}

resource "oci_apigateway_deployment" "queue_length_deployment" {
  # depends_on = [ null_resource.function_Push2OCIR ]
  compartment_id = var.compartment_ocid
  defined_tags   = {}
  display_name   = "queue-api-deployment_${random_id.tag.hex}"
  freeform_tags  = {}
  gateway_id     = oci_apigateway_gateway.api_gateway.id
  path_prefix    = var.path_prefix

  specification {
    logging_policies {

      execution_log {
        is_enabled = true
        log_level  = "INFO"
      }
    }

    request_policies {




      mutual_tls {
        allowed_sans                     = []
        is_verified_certificate_required = false
      }
    }


    routes {
      methods = [
        "ANY"
      ]
      path = "/${var.consumer_route_path}"

      backend {
        connect_timeout_in_seconds = 0
        function_id                = oci_functions_function.function.id
        is_ssl_verify_disabled     = false
        read_timeout_in_seconds    = 0
        send_timeout_in_seconds    = 0
        status                     = 0
        type                       = "ORACLE_FUNCTIONS_BACKEND"
      }

      logging_policies {

        execution_log {
          is_enabled = false
        }
      }

      
    }
  }


}

