output "managed_identity_principal_id" {
  description = "The pricipal id of the managed identity"
  value       = var.managed_identity_type != "SystemAssigned" ? azurerm_user_assigned_identity.uid.principal_id : var.system_assigned_managed_identity_principal_id
}

output "service_endpoint_id" {
  description = "The id of the service endpoint"
  value       = azuredevops_serviceendpoint_azurerm.azure_devops_service_endpoint_azurerm.id
}

output "service_endpoint_name" {
  description = "The project name of the service endpoint is made with"
  value       = azuredevops_serviceendpoint_azurerm.azure_devops_service_endpoint_azurerm.service_endpoint_name
}

output "service_endpoint_project_id" {
  description = "The project id of the service endpoint is made with"
  value       = azuredevops_serviceendpoint_azurerm.azure_devops_service_endpoint_azurerm.project_id
}

output "service_endpoint_service_principal_id" {
  description = "The service principal id service endpoint is made with"
  value       = azuredevops_serviceendpoint_azurerm.azure_devops_service_endpoint_azurerm.service_principal_id
}
