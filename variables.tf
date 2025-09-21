variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

# Networking — either provide an existing subnet_id, or set create_network = true.
variable "subnet_id" {
  description = "Existing subnet ID to place NICs in. If null, set create_network=true."
  type        = string
  default     = null
}
variable "my_ip" {
  default = ""
}
variable "create_network" {
  description = "If true, create a VNet/Subnet to deploy into."
  type        = bool
  default     = false
}

variable "vnet_name" {
  type    = string
  default = "vnet-azvms"
}

variable "vnet_cidr" {
  type    = string
  default = "10.42.0.0/16"
}

variable "subnet_name" {
  type    = string
  default = "subnet-azvms"
}

variable "subnet_cidr" {
  type    = string
  default = "10.42.1.0/24"
}

# Auth
variable "admin_username" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

# Sizes
variable "control_vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "service_vm_size" {
  type    = string
  default = "Standard_B2s"
}

# Service set; default to two service nodes
variable "service_nodes" {
  description = "Map of service node names -> optional metadata."
  type        = map(object({}))
  default     = {
    service-1 = {}
    service-2 = {}
  }
}

# Public IPs
variable "control_public_ip" {
  type    = bool
  default = true
}

variable "service_public_ip" {
  type    = bool
  default = false
}

# Image
variable "image" {
  description = "Ubuntu image reference."
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

# Script args (optional) to pass into the embedded scripts via env
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

# Common tags
variable "tags" {
  type    = map(string)
  default = {}
}
