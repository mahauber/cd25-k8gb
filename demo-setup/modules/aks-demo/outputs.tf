# add output of dns zone and information that the dns zone needs to be delegated to the nameservers and specify the nameservers
output "information" {
  value = "Please delegate ${azurerm_dns_zone.root.name} to the following nameservers: ${join(", ", azurerm_dns_zone.root.name_servers)}"
}