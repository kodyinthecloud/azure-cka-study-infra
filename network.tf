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

# Network Security Group
resource "azurerm_network_security_group" "this" {
  count               = var.create_network ? 1 : 0
  name                = "${var.subnet_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Rule 1: Allow inbound SSH (22) from your public IP

resource "azurerm_network_security_rule" "ssh_from_myip" {
  count                       = var.create_network ? 1 : 0
  name                        = "Allow-SSH-MyIP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.my_ip
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[0].name
}

# Rule 2: Allow all VNet-to-VNet traffic
resource "azurerm_network_security_rule" "intra_vnet" {
  count                       = var.create_network ? 1 : 0
  name                        = "Allow-IntraVNet"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[0].name
}

# Rule 3: Allow all outbound traffic
resource "azurerm_network_security_rule" "allow_all_outbound" {
  count                       = var.create_network ? 1 : 0
  name                        = "Allow-All-Outbound"
  priority                    = 300
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[0].name
}

# Associate NSG to the subnet
resource "azurerm_subnet_network_security_group_association" "this" {
  count                     = var.create_network ? 1 : 0
  subnet_id                 = azurerm_subnet.this[0].id
  network_security_group_id = azurerm_network_security_group.this[0].id
}