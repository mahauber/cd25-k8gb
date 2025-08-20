resource "random_id" "server" {
  keepers = {
    azi_id = 1
  }

  byte_length = 8
}

resource "azurerm_resource_group" "traffic-manager" {
  name     = "traffic-manager"
  location = "West Europe"
}

resource "azurerm_traffic_manager_profile" "traffic-manager" {
  name                   = random_id.server.hex
  resource_group_name    = azurerm_resource_group.traffic-manager.name
  traffic_routing_method = "Weighted" # Geographic # Performance # Priority
  traffic_view_enabled   = true

  dns_config {
    relative_name = random_id.server.hex
    ttl           = 100
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }

  tags = {
    environment = "Production"
  }
}