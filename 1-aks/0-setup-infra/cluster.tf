resource "azurerm_kubernetes_cluster" "main" {
  for_each = { for cluster in var.clusters : cluster.name => cluster }

  name                              = each.value.name
  location                          = each.value.location
  resource_group_name               = azurerm_resource_group.main[each.key].name
  kubernetes_version                = var.kubernetes_version
  node_resource_group               = "rg-${each.value.name}-aks-nodes" # optional
  sku_tier                          = "Free"                            # optional
  dns_prefix                        = "kubernetes"
  role_based_access_control_enabled = true # optional
  local_account_disabled            = true # optional

  default_node_pool {
    name                         = "system"
    node_count                   = 1
    vm_size                      = "Standard_B4ms"
    orchestrator_version         = var.kubernetes_version
    os_disk_type                 = "Managed"                 # optional
    type                         = "VirtualMachineScaleSets" # optional
    auto_scaling_enabled         = false                     # optional
    only_critical_addons_enabled = false                     # optional, this should be set to true to separate system and user node pools
    upgrade_settings {
      max_surge = "10%" # optional, but due to bug in the provider it should be specified
    }
  }

  network_profile {
    # network_plugin = "none" # to install your own cni like cilium
    # Cilium CNI managed by Azure AKS:
    network_plugin      = "azure"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
    network_plugin_mode = "overlay"
  }

  # Azure AD authentication with Azure RBAC
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  identity {
    type = "SystemAssigned"
  }
}

# second cluster node pool
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = { for cluster in var.clusters : cluster.name => cluster }

  name                  = "application"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main[each.key].id
  vm_size               = "Standard_B2ms"
  node_count            = 1
  auto_scaling_enabled  = true                   # optional
  min_count             = 1                      # optional
  max_count             = 2                      # optional
  mode                  = "User"                 # optional
  orchestrator_version  = var.kubernetes_version # optional, 1.28.3 is latest (-> space for upgrade to 1.28.3)
  os_disk_type          = "Managed"              # optional
}

# assign cluster admin role to the current user
resource "azurerm_role_assignment" "aks_cluster_admin_to_user" {
  for_each = { for cluster in var.clusters : cluster.name => cluster }

  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_kubernetes_cluster.main[each.key].id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
}