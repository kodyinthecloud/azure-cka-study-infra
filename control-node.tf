# Optional Public IP
resource "azurerm_public_ip" "control" {
  count               = var.control_public_ip ? 1 : 0
  name                = "pip-control"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "control" {
  name                = "nic-control"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = local.effective_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.control_public_ip ? azurerm_public_ip.control[0].id : null
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "control" {
  name                = "vm-control"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.control_vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.control.id
  ]

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
    name                 = "osdisk-control"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = merge(var.tags, { role = "control" })
}

# Run Command for control node
resource "azurerm_virtual_machine_run_command" "control" {
  name               = "control-bootstrap"
  virtual_machine_id = azurerm_linux_virtual_machine.control.id
  location = var.location

  # Embed the module's script file
  source {
    script = file("${path.module}/scripts/bootstrap.sh")
  }

  # Pass env vars to the script (optional)
  protected_parameter {
    name  = "environmentVariables"
    value = jsonencode([
      for k, v in var.control_script_env : {
        name  = k
        value = v
      }
    ])
  }
  tags               = var.tags
}
