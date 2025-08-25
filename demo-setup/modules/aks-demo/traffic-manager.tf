resource "random_id" "server" {
  keepers = {
    azi_id = 1
  }

  byte_length = 8
}

resource "azurerm_resource_group" "traffic-manager" {
  name     = "traffic-manager"
  location = "germanywestcentral"
}

resource "azurerm_traffic_manager_profile" "main" {
  name                   = "traf-podinfo-demo-cd25"
  resource_group_name    = azurerm_resource_group.traffic-manager.name
  traffic_routing_method = "Weighted" # Geographic # Performance # Priority
  traffic_view_enabled   = true

  dns_config {
    relative_name = "traf-podinfo-demo-cd25"
    ttl           = 100
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 10
    timeout_in_seconds           = 5
    tolerated_number_of_failures = 2
  }
}

resource "azurerm_traffic_manager_external_endpoint" "aks" {
  for_each = { for idx, cluster in var.clusters : cluster.name => cluster }

  name                 = "traf-${each.value.name}"
  profile_id           = azurerm_traffic_manager_profile.main.id
  target               = "${each.value.name}.traf.k8st.cc"
  priority             = each.value.name == "aks-gwc" ? 1 : 2
  weight               = each.value.name == "aks-gwc" ? 70 : 30
}
