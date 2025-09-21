# Optional Public IPs for services
resource "azurerm_public_ip" "service" {
  for_each            = var.service_public_ip ? var.service_nodes : {}
  name                = "pip-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "service" {
  for_each            = var.service_nodes
  name                = "nic-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = local.effective_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.service_public_ip ? azurerm_public_ip.service[each.key].id : null
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "service" {
  for_each              = var.service_nodes
  name                  = "vm-${each.key}"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.service_vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.service[each.key].id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  os_disk {
    name                 = "osdisk-${each.key}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = merge(var.tags, { role = "service", node = each.key })
}

# Run Command for each service node
resource "azurerm_virtual_machine_run_command" "service" {
  for_each           = var.service_nodes
  name               = "bootstrap-${each.key}"
  virtual_machine_id = azurerm_linux_virtual_machine.service[each.key].id
  location = var.location

  source {
    script = file("${path.module}/scripts/bootstrap.sh")
  }

  tags               = var.tags
}
