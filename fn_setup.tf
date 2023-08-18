## Copyright (c) 2020, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "null_resource" "function_Push2OCIR" {
  depends_on = [
    oci_functions_application.fn_application,oci_artifacts_container_repository.fn_container_repository
  ]
#   triggers = {
#     always_run = "${timestamp()}"
#   }

	provisioner "local-exec" {
    command ="echo '${var.ocir_user_password}' |  docker login ${local.ocir_docker_repository} --username ${local.ocir_namespace}/${var.ocir_user_name} --password-stdin"
    
	}
  provisioner "local-exec" {

   
   command = <<-EOT
      
      git clone https://github.com/oracle-devrel/oci-arch-queue-oke-demo.git
      

    EOT
    
  }

  provisioner "local-exec" {
    command     = <<-EOT
    
    
    mvn clean package
    docker build -t ${local.ocir_docker_repository}/${local.ocir_namespace}/${oci_artifacts_container_repository.fn_container_repository.display_name}/queuelength .
    docker push ${local.ocir_docker_repository}/${local.ocir_namespace}/${oci_artifacts_container_repository.fn_container_repository.display_name}/queuelength
	EOT
    working_dir = "${path.root}/oci-arch-queue-oke-demo/queue-length-function"
    
  }
  
  
}



