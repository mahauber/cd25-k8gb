resource "azurerm_resource_group" "fleetmanager" {
  name     = "rg-aks-fleetmanager"
  location = "germanywestcentral"
}

resource "azapi_resource" "fleetmanager" {
  type = "Microsoft.ContainerService/fleets@2025-03-01"
  name = "fleetmanager"
  parent_id = azurerm_resource_group.fleetmanager.id
  identity {
    type = "SystemAssigned"
  }
  location = azurerm_resource_group.fleetmanager.location
  body = {
    properties = {
      hubProfile = {
        agentProfile = {
          # subnetId = "string" # The ID of the subnet which the Fleet hub node will join on startup. If this is not specified, a vnet and subnet will be generated and used.
          vmSize = "Standard_B2ms"
        }
        apiServerAccessProfile = {
          enablePrivateCluster = false
          enableVnetIntegration = false
          # subnetId = "string" # The subnet to be used when apiserver vnet integration is enabled. It is required when creating a new Fleet with BYO vnet.
        }
        # dnsPrefix = "string"
      }
    }
  }
}

resource "azurerm_kubernetes_fleet_member" "main" {
  for_each = { for cluster in var.clusters : cluster.name => cluster }

  kubernetes_cluster_id = azurerm_kubernetes_cluster.main[each.key].id
  kubernetes_fleet_id   = azapi_resource.fleetmanager.id
  name                  = each.key
}

resource "azurerm_role_assignment" "fleet_cluster_admin_to_user" {
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azapi_resource.fleetmanager.id
  role_definition_name = "Azure Kubernetes Fleet Manager RBAC Cluster Admin"
}
