data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "azuredevops_project" "project_id" {
  name = var.azuredevops_project_name
}

locals {
  default_managed_identity_type        = var.managed_identity_type != "SystemAssigned" ? "UserAssigned" : "SystemAssigned"
  default_managed_identity_name        = var.managed_identity_name != null ? var.managed_identity_name : "msi-azdo-${var.azuredevops_project_name}-${var.azuredevops_organization_guid}"
  default_managed_identity_description = var.managed_identity_description != null ? var.managed_identity_description : "This managed identity is for the federated credential of Azure DevOps of the project ${var.azuredevops_project_name}, in the organization ${var.azuredevops_organization_name} with guid ${var.azuredevops_organization_guid}"
}

module "rg" {
  source = "libre-devops/rg/azurerm"

  count = var.rg_id == null ? 1 : 0

  rg_name  = var.rg_name
  location = var.location
  tags     = var.tags
}

locals {
  rg_parts           = var.rg_id != null ? split("/", var.rg_id) : null
  rg_name            = local.rg_parts != null ? local.rg_parts[4] : null
  rg_subscription_id = local.rg_parts != null ? local.rg_parts[2] : null
}

resource "azurerm_user_assigned_identity" "uid" {
  count               = local.default_managed_identity_type != "SystemAssigned" ? 1 : 0
  name                = local.default_managed_identity_name
  resource_group_name = local.rg_name != null ? local.rg_name : module.rg[0].rg_name
  location            = var.location
  tags                = var.tags
}

resource "azuredevops_serviceendpoint_azurerm" "azure_devops_service_endpoint_azurerm" {
  depends_on                             = [azurerm_role_assignment.assign_spn_to_subscription[0]]
  project_id                             = data.azuredevops_project.project_id.id
  service_endpoint_name                  = var.managed_identity_name != null ? var.managed_identity_name : local.default_managed_identity_name
  description                            = var.managed_identity_description
  service_endpoint_authentication_scheme = "ManagedServiceIdentity"

  credentials {
    serviceprincipalid = var.system_assigned_managed_identity_principal_id == null ? azurerm_user_assigned_identity.uid[0].client : var.system_assigned_managed_identity_client_id
  }

  azurerm_spn_tenantid      = data.azurerm_client_config.current.tenant_id
  azurerm_subscription_id   = data.azurerm_subscription.current.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.current.display_name
}

resource "azurerm_role_assignment" "assign_spn_to_subscription" {
  count                = var.attempt_assign_role_to_spn == true ? 1 : 0
  principal_id         = var.system_assigned_managed_identity_principal_id == null ? azurerm_user_assigned_identity.uid[0].principal_id : var.system_assigned_managed_identity_principal_id
  scope                = data.azurerm_subscription.current.id
  role_definition_name = var.role_definition_name_to_assign
}

# resource "azurerm_federated_identity_credential" "fed_cred_managed_identity" {
#   count               = var.managed_identity_type == "UserAssigned" ? 1 : 0
#   name                = local.default_managed_identity_name
#   resource_group_name = local.rg_name
#   parent_id           = azurerm_user_assigned_identity.uid[0].id
#   audience            = ["api://AzureADTokenExchange"]
#   issuer              = azuredevops_serviceendpoint_azurerm.azure_devops_service_endpoint_azurerm.workload_identity_federation_issuer
#   subject             = azuredevops_serviceendpoint_azurerm.azure_devops_service_endpoint_azurerm.workload_identity_federation_subject
# }