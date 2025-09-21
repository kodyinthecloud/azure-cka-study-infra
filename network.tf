# Optional VNet/Subnet (only created if create_network = true)
resource "azurerm_virtual_network" "this" {
  count               = var.create_network ? 1 : 0
  name                = var.vnet_name
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  count                = var.create_network ? 1 : 0
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [var.subnet_cidr]
}

# Simple guard: fail early if we have neither subnet_id nor create_network=true
resource "null_resource" "assert_subnet_present" {
  triggers = {
    subnet_present = tostring(local.effective_subnet_id != null)
  }

  lifecycle {
    precondition {
      condition     = local.effective_subnet_id != null
      error_message = "No subnet to deploy into. Provide var.subnet_id or set create_network=true."
    }
  }
}
