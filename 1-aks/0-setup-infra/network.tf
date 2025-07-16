# ######################
# ## VIRTUAL NETWORKS ##
# ######################

# resource "azurerm_virtual_network" "main" {
#   for_each = { for cluster in var.clusters : cluster.name => cluster }

#   name                = "vnet-${each.key}"
#   resource_group_name = azurerm_resource_group.main[each.key].name
#   location            = azurerm_resource_group.main[each.key].location
#   address_space       = ["10.0.0.0/16"]
# }

# #############
# ## SUBNETS ##
# #############

# resource "azurerm_subnet" "main" {
#   for_each = { for cluster in var.clusters : cluster.name => cluster }

#   name                 = "aks"
#   resource_group_name  = azurerm_resource_group.main[each.key].name
#   virtual_network_name = azurerm_virtual_network.main[each.key].name
#   address_prefixes     = ["10.0.1.0/24"]
# }
