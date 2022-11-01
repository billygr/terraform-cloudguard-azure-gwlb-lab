output "resource_group_name-serviceA" {
  value = azurerm_resource_group.rg-serviceA.name
}

output "resource_group_name-serviceB" {
  value = azurerm_resource_group.rg-serviceB.name
}

output "public_ip_address-serviceA" {
  value = azurerm_linux_virtual_machine.vm-serviceA.public_ip_address
}

output "public_ip_address-serviceB" {
  value = azurerm_linux_virtual_machine.vm-serviceB.public_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}
