############################################
# Core
############################################
variable "resource_group_name" {
  description = "Name of the Azure Resource Group to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region short name (e.g., eastus, westus2)."
  type        = string
}

############################################
# Networking
############################################
variable "create_network" {
  description = "If true, create a VNet/Subnet; if false, an existing subnet_id must be provided."
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Existing subnet ID to place NICs in. Set to null if create_network = true."
  type        = string
  default     = null
}

variable "vnet_name" {
  description = "Name for the VNet (used only when create_network = true)."
  type        = string
  default     = "vnet-azvms"
}

variable "vnet_cidr" {
  description = "CIDR for the VNet (used only when create_network = true)."
  type        = string
  default     = "10.42.0.0/16"
}

variable "subnet_name" {
  description = "Name for the Subnet (used only when create_network = true)."
  type        = string
  default     = "subnet-azvms"
}

variable "subnet_cidr" {
  description = "CIDR for the Subnet (used only when create_network = true)."
  type        = string
  default     = "10.42.1.0/24"
}

############################################
# Access / Auth
############################################
variable "admin_username" {
  description = "Admin username for the VMs."
  type        = string
  default     = "adm"
}

variable "ssh_public_key" {
  description = "OpenSSH-formatted public key used for admin access."
  type        = string
}

variable "my_ip" {
  description = "Optional public IPv4 address of the operator (used for allow-listing). Leave empty to skip."
  type        = string

}

variable "tenant_id" {
  description = "Azure AD tenant ID (UUID). Leave empty to ignore."
  type        = string

}

variable "subscription_id" {
  description = "Azure subscription ID (UUID). Leave empty to ignore."
  type        = string

}

############################################
# Compute Sizing
############################################
variable "control_vm_size" {
  description = "Azure VM size for the control node."
  type        = string
  default     = "Standard_B2s"
}

variable "service_vm_size" {
  description = "Azure VM size for service nodes."
  type        = string
  default     = "Standard_B2s"
}

############################################
# Node Set
############################################
variable "service_nodes" {
  description = "Map of service node names to optional metadata."
  type        = map(object({}))
  default     = {
    service-1 = {}
    service-2 = {}
  }
}

############################################
# Public IP Allocation
############################################
variable "control_public_ip" {
  description = "Whether to assign a public IP to the control node."
  type        = bool
  default     = true
}

variable "service_public_ip" {
  description = "Whether to assign public IPs to service nodes."
  type        = bool
  default     = false
}

############################################
# Image (Ubuntu default)
############################################
variable "image" {
  description = "Marketplace image reference for the VMs."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

############################################
# Script Arguments (optional)
############################################
variable "control_script_env" {
  description = "Map of env vars passed to the control run command."
  type        = map(string)
  default     = {}
}

variable "service_script_env" {
  description = "Map of env vars passed to each service run command."
  type        = map(string)
  default     = {}
}

############################################
# Tags
############################################
variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
