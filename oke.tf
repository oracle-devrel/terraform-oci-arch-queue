## Copyright (c) 2020, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

module "oke-quickstart" {
  source = "github.com/oracle-quickstart/terraform-oci-oke-quickstart?ref=0.9.2"

  providers = {
    oci             = oci
    oci.home_region = oci.home_region
  }

  # Oracle Cloud Infrastructure Tenancy and Compartment OCID
  tenancy_ocid     = var.tenancy_ocid
  compartment_ocid = var.compartment_ocid
  region           = var.region

  # Note: Just few arguments are showing here to simplify the basic example. All other arguments are using default values.
  # App Name to identify deployment. Used for naming resources.
  app_name    = "Queue_Demo"
  k8s_version = var.k8s_version

  # Freeform Tags + Defined Tags. Tags are applied to all resources.
  tag_values = { "freeformTags" = { "Environment" = "Development", "DeploymentType" = "full", "Quickstart" = "Queue_Demo" }, "definedTags" = {} }

  # VCN for OKE arguments
  vcn_cidr_blocks = var.vcn_cidr_blocks
  # extra_security_lists                      = local.extra_security_lists
  # extra_subnets                             = local.extra_subnets
  # extra_security_list_name_for_api_endpoint = "turn_for_k8s_api_security_list"

  # OKE Node Pool 1 arguments
  node_pool_cni_type_1                 = "FLANNEL_OVERLAY" # Use "OCI_VCN_IP_NATIVE" for VCN Native PODs Network. If the node pool 1 uses the OCI_VCN_IP_NATIVE, the cluster will also be configured with same cni
  node_pool_autoscaler_enabled_1       = true
  node_pool_name_1                     = "Default"
  node_pool_initial_num_worker_nodes_1 = 3 # Minimum number of nodes in the node pool 1 (Default)
  node_pool_max_num_worker_nodes_1     = 3 # Maximum number of nodes in the node pool 1 (Default)
  node_pool_instance_shape_1           = var.node_pool_instance_shape_1
  metrics_server_enabled               = false
  # node_pool_boot_volume_size_in_gbs_1  = 120
  # extra_node_pools                     = local.extra_node_pools
  # extra_security_list_name_for_nodes   = "turn_for_nodes_security_list"

  # Cluster Tools
  # ingress_nginx_enabled = true
  # cert_manager_enabled  = true
}

# Get OKE options
locals {
  cluster_k8s_latest_version   = reverse(sort(data.oci_containerengine_cluster_option.oke.kubernetes_versions))[0]
  node_pool_k8s_latest_version = reverse(sort(data.oci_containerengine_node_pool_option.oke.kubernetes_versions))[0]
}

# resource "null_resource" "kubeconfigvar" {
#   depends_on = [module.oke-quickstart]
#   provisioner "local-exec" {

#     command     = "$Env:kubeconfig='./generated/kubeconfig'"
#     interpreter = ["pwsh", "-Command"]
#   }
# }

resource "null_resource" "keda_setup" {
  depends_on = [module.oke-quickstart, oci_apigateway_deployment.queue_length_deployment,oci_identity_policy.queue_demo_policies]
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command     = <<-EOT
      export KUBECONFIG=${path.module}/generated/kubeconfig
      kubectl apply --server-side -f https://github.com/kedacore/keda/releases/download/v2.11.2/keda-2.11.2.yaml 
      kubectl create secret docker-registry queueoke-secret --docker-server='${local.ocir_docker_repository}/${local.ocir_namespace}/${oci_artifacts_container_repository.fn_container_repository.display_name}' --docker-username='${local.ocir_namespace}/${var.ocir_user_name}' --docker-password='${var.ocir_user_password}'
      
	  EOT
    
  }
  #  provisioner "local-exec" {

   
  #  command = <<-EOT
      
  #     git clone https://github.com/oracle-devrel/oci-arch-queue-oke-demo.git
      

  #   EOT
    
  # }
  provisioner "local-exec" {

   
   command = <<-EOT
      
      
	  git checkout  terraformchanges

    EOT
    working_dir = "${path.root}/oci-arch-queue-oke-demo/"
  }
  provisioner "local-exec" {
    command     = <<-EOT
    
    
    mvn clean package
    docker build -t ${local.ocir_docker_repository}/${local.ocir_namespace}/${oci_artifacts_container_repository.fn_container_repository.display_name}/queueoke .
    EOT
    working_dir = "${path.root}/oci-arch-queue-oke-demo/oke-consumer"
    
  }
  provisioner "local-exec" {
    command ="echo '${var.ocir_user_password}' |  docker login ${local.ocir_docker_repository} --username ${local.ocir_namespace}/${var.ocir_user_name} --password-stdin"
    
	}
  provisioner "local-exec" {
    command     = <<-EOT
    docker push ${local.ocir_docker_repository}/${local.ocir_namespace}/${oci_artifacts_container_repository.fn_container_repository.display_name}/queueoke:latest
    sed -i 's|IMAGE_NAME|${local.ocir_docker_repository}/${local.ocir_namespace}/${oci_artifacts_container_repository.fn_container_repository.display_name}/queueoke:latest|g' queue-oke.yaml
    sed -i 's|API_GATEWAY_URL|${oci_apigateway_deployment.queue_length_deployment.endpoint}${var.consumer_route_path}|g' so-object.yaml
   
    EOT
    working_dir = "${path.root}/oci-arch-queue-oke-demo/oke-consumer"
    
  }

    provisioner "local-exec" {
    command     = <<-EOT
    export KUBECONFIG=${path.module}/generated/kubeconfig
    kubectl apply -f ${path.root}/oci-arch-queue-oke-demo/oke-consumer/so-object.yaml
    kubectl apply -f ${path.root}/oci-arch-queue-oke-demo/oke-consumer/queue-oke.yaml
    kubectl set env deployment/queueoke IMAGE_NAME='${local.ocir_docker_repository}/${local.ocir_namespace}/$${oci_artifacts_container_repositoryfn_container_repository.display_name}/queueoke:latest'
    kubectl set env deployment/queueoke QUEUE_ID='${oci_queue_queue.test_queue.id}'
    kubectl set env deployment/queueoke DP_ENDPOINT='${oci_queue_queue.test_queue.messages_endpoint}'
    
    EOT
    
    
  }


}
