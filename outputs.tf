output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "app_subnet_id" {
  value = azurerm_subnet.app.id
}

output "mgmt_subnet_id" {
  value = azurerm_subnet.mgmt.id
}
