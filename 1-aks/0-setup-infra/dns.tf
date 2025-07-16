resource "azurerm_resource_group" "dns" {
  name     = "rg-dns"
  location = "germanywestcentral"
}

resource "azurerm_dns_zone" "root" {
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.dns.name
}

resource "azurerm_dns_zone" "child" {
  name                = "${var.loadbalanced_dns_zone_prefix}.${var.dns_zone_name}"
  resource_group_name = azurerm_resource_group.dns.name
}

# delegate subdomain to child DNS zone (NS record)
resource "azurerm_dns_ns_record" "child" {
  name                = var.loadbalanced_dns_zone_prefix
  zone_name           = azurerm_dns_zone.root.name
  resource_group_name = azurerm_resource_group.dns.name
  ttl                 = 300
  records = azurerm_dns_zone.child.name_servers
}

# assign DNS Zone Contributor role to the AKS cluster's kubelet identity
resource "azurerm_role_assignment" "dns_zone_contributor_child" {
  for_each = { for cluster in var.clusters : cluster.name => cluster }

  principal_id         = azurerm_kubernetes_cluster.main[each.key].kubelet_identity[0].object_id
  role_definition_name = "DNS Zone Contributor"
  scope                = azurerm_resource_group.dns.id
}