output "control-node-public-ip" {
  value = azurerm_linux_virtual_machine.control.public_ip_address
}

output "control-node-private-ip" {
  value = azurerm_linux_virtual_machine.control.private_ip_address
}

output "service_private_ips" {
  value = {
    for name, nic in azurerm_network_interface.service :
    name => nic.ip_configuration[0].private_ip_address
  }
}

output "service_public_ips" {
  value = var.service_public_ip ? {
    for name, pip in azurerm_public_ip.service :
    name => pip.ip_address
  } : {}
}