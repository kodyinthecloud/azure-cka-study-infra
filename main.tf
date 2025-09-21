terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0"
    }
  }
}

locals {
  # Pick the subnet: prefer explicit var.subnet_id; else use the optional created subnet.
  effective_subnet_id = coalesce(
    var.subnet_id,
    try(azurerm_subnet.this[0].id, null)
  )
}
