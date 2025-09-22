![Screenshot](logo.jpeg)

# azure-cka-study-infra · Azure VM cluster module 

![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A5%201.5-623CE4?logo=terraform)
![Provider](https://img.shields.io/badge/azurerm-%E2%89%A5%203.110.0-0072C6?logo=microsoft-azure)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04_LTS-E95420?logo=ubuntu)
![License](https://img.shields.io/badge/License-MIT-informational)

> [!TIP]
> Tiny, practical Terraform module to stand up a **control node** and **Two service nodes** on Azure with optional **VNet/Subnet + NSG**, and a **Run Command bootstrap** that installs containerd + kubelet/kubeadm/kubectl on every node.

---

## Table of Contents

- [Features](#features)
- [Module Layout](#module-layout)
- [Requirements](#requirements)
- [Outputs](#outputs)
- [Quick Start (Create VNet + NSG)](#quick-start-create-vnet--nsg)
- [Alternative (Existing Subnet, Skip NSG)](#alternative-existing-subnet-skip-nsg)
- [Bootstrap Script](#bootstrap-script)
- [SSH Examples](#ssh-examples)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Inputs](#inputs)

---

## Features

- **1× control VM** (separate file) + **service VMs** via `for_each`
- **Optional VNet/Subnet** creation (`create_network`)
- **Optional Subnet NSG** (`create_nsg`)
    - allow SSH (22/TCP) **from your IP**
    - allow **intra-VNet** communication
    - allow **all egress**
- **Run Command** bootstrap on all nodes (containerd + kube tools)
- Clean outputs: maps of private/public IPs for the service fleet

---

## Module Layout

```
modules/
└─ az-vms/
   ├─ main.tf
   ├─ variables.tf
   ├─ control.tf
   ├─ services.tf
   ├─ network.tf
   ├─ outputs.tf
   └─ scripts/
      └─ bootstrap.sh
```

> [!NOTE]
> Default image is **Ubuntu 22.04 LTS**. Provide a **public** SSH key to the module. Never pass private keys to Terraform or the VM.

---

## Requirements

- Terraform **≥ 1.5**
- Provider `hashicorp/azurerm` **≥ 3.110.0**
- Azure RBAC capable of creating VM/Network resources (or supply an existing subnet)
- SSH keypair on your machine (use `file("~/.ssh/id_ed25519.pub")` or similar)

---

## Outputs

| Name | Type | Description |
|---|---|---|
| `subnet_id` | string | Subnet used for NICs |
| `control_private_ip` | string | Control VM private IP |
| `control_public_ip` | string\\|null | Control VM public IP (null if disabled) |
| `service_private_ips` | map(string) | Map of service name → private IP |
| `service_public_ips` | map(string) | Map of service name → public IP (empty if disabled) |

---

## Quick Start (Create VNet + NSG)

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0"
    }
  }
}

provider "azurerm" {
  features {}
  # labs only:
  # skip_provider_registration = true
}

module "az_vms" {
  source              = "./modules/az-vms"
  
  # Required
  resource_group_name = "rg-demo"
  subscription_id     = "00000000-0000-0000-0000-000000000000"  
  tenant_id           = "00000000-0000-0000-0000-000000000000"
  ssh_public_key = file("~/.ssh/id_ed25519.pub")  # PUBLIC key
  location            = "eastus"

  # Network
  # Option 1 -  create VNet/Subnet + NSG
  create_network = true
  create_nsg     = true
  vnet_name      = "vnet-demo"
  vnet_cidr      = "10.1.0.0/16"
  subnet_name    = "subnet-demo"
  subnet_cidr    = "10.1.2.0/24"
  my_ip          = "203.0.113.25/32"   # SSH allowlist
  
  # Option 2 - use existing subnet (skip VNet/Subnet + NSG)
  submet_id =  "subscriptions/xxxx/resourceGroups/rg-demo/providers/Microsoft.Network/virtualNetworks/vnet-demo/subnets/subnet-app"
  
  # Access
  admin_username = "infra-xadm" # default: infra-adm
  

  tags = { project = "demo", env = "dev" }
}
```

---

## Alternative (Existing Subnet, Skip NSG)

```hcl
module "az_vms" {
  source              = "./modules/az-vms"
  resource_group_name = "learn-rg"
  location            = "eastus"

  create_network = false
  create_nsg     = false
  subnet_id      = "/subscriptions/xxxx/resourceGroups/learn-rg/providers/Microsoft.Network/virtualNetworks/learn-vnet/subnets/app"

  admin_username = "xadm"
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  control_public_ip = true
  service_public_ip = false
  
}
```

---

## Bootstrap Script

Place at `modules/az-vms/scripts/bootstrap.sh` and reference via Run Command in the module.

```bash
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

VERSION="${VERSION:-1.30}"

sudo rm -rf /var/lib/apt/lists/* || true
sudo mkdir -p /var/lib/apt/lists/partial
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gpg apt-transport-https

# Install containerd (fallback to Docker repo if needed)
if ! sudo apt-get install -y containerd; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release; echo $UBUNTU_CODENAME) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y containerd.io
fi
sudo systemctl enable --now containerd

sudo mkdir -p /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${VERSION}/deb/Release.key" \
  | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 0644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${VERSION}/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
sudo chmod 0644 /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl containerd containerd.io || true
```

---

## SSH Examples

Jump through control to a service node from your laptop:

```bash
ssh -J xadm@<CONTROL_PUBLIC_IP> xadm@<SERVICE_PRIVATE_IP>
# Example:
ssh -J xadm@4.246.216.116 xadm@10.60.1.5
```

Force a specific key:

```bash
ssh -J xadm@<CONTROL_PUBLIC_IP> -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes xadm@<SERVICE_PRIVATE_IP>
```

---

## Troubleshooting

- **403 `AuthorizationFailed`**: you lack RBAC (common in labs).  
  Use a subscription/RG where you have **Contributor/Network Contributor**, or set `create_network=false` / `create_nsg=false` and pass an existing `subnet_id`.

- **Run Command exit 100 / apt list errors**:  
  Ensure the script recreates `/var/lib/apt/lists/partial` and runs `apt-get update` before any install.

- **Non-interactive prompts (`/dev/tty`, `debconf`)**:  
  Script sets `DEBIAN_FRONTEND=noninteractive` and uses `gpg --batch --yes`.

- **Control → Service SSH fails**:  
  Use ProxyJump from your laptop, or agent forwarding (`ssh -A`). Ensure NSG has `VirtualNetwork` allow inbound.

---

## License

MIT — feel free to copy, adapt, and use in your projects.


## Requirements


| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.110.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.110.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_virtual_machine.control](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_linux_virtual_machine.service](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.control](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.service](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.allow_all_outbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.intra_vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.ssh_from_myip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_public_ip.control](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.service](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_machine_run_command.control](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_run_command) | resource |
| [azurerm_virtual_machine_run_command.service](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_run_command) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | Admin username for the VMs. | `string` | `"infra-adm"` | no |
| <a name="input_control_public_ip"></a> [control\_public\_ip](#input\_control\_public\_ip) | Whether to assign a public IP to the control node. | `bool` | `true` | no |
| <a name="input_control_script_env"></a> [control\_script\_env](#input\_control\_script\_env) | Map of env vars passed to the control run command. | `map(string)` | `{}` | no |
| <a name="input_control_vm_size"></a> [control\_vm\_size](#input\_control\_vm\_size) | Azure VM size for the control node. | `string` | `"Standard_B2s"` | no |
| <a name="input_create_network"></a> [create\_network](#input\_create\_network) | If true, create a VNet/Subnet; if false, an existing subnet\_id must be provided. | `bool` | `false` | no |
| <a name="input_image"></a> [image](#input\_image) | Marketplace image reference for the VMs. | <pre>object({<br/>    publisher = string<br/>    offer     = string<br/>    sku       = string<br/>    version   = string<br/>  })</pre> | <pre>{<br/>  "offer": "0001-com-ubuntu-server-jammy",<br/>  "publisher": "Canonical",<br/>  "sku": "22_04-lts-gen2",<br/>  "version": "latest"<br/>}</pre> | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region short name (e.g., eastus, westus2). | `string` | n/a | yes |
| <a name="input_my_ip"></a> [my\_ip](#input\_my\_ip) | Optional public IPv4 address of the operator (used for allow-listing). Leave empty to skip. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the Azure Resource Group to deploy into. | `string` | n/a | yes |
| <a name="input_service_nodes"></a> [service\_nodes](#input\_service\_nodes) | Map of service node names to optional metadata. | `map(object({}))` | <pre>{<br/>  "service-1": {},<br/>  "service-2": {}<br/>}</pre> | no |
| <a name="input_service_public_ip"></a> [service\_public\_ip](#input\_service\_public\_ip) | Whether to assign public IPs to service nodes. | `bool` | `true` | no |
| <a name="input_service_script_env"></a> [service\_script\_env](#input\_service\_script\_env) | Map of env vars passed to each service run command. | `map(string)` | `{}` | no |
| <a name="input_service_vm_size"></a> [service\_vm\_size](#input\_service\_vm\_size) | Azure VM size for service nodes. | `string` | `"Standard_B2s"` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | OpenSSH-formatted public key used for admin access. | `string` | n/a | yes |
| <a name="input_subnet_cidr"></a> [subnet\_cidr](#input\_subnet\_cidr) | CIDR for the Subnet (used only when create\_network = true). | `string` | `"10.42.1.0/24"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Existing subnet ID to place NICs in. Set to null if create\_network = true. | `string` | `null` | no |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Name for the Subnet (used only when create\_network = true). | `string` | `"subnet-azvms"` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Azure subscription ID (UUID). Leave empty to ignore. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common resource tags. | `map(string)` | `{}` | no |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | Azure AD tenant ID (UUID). Leave empty to ignore. | `string` | n/a | yes |
| <a name="input_vnet_cidr"></a> [vnet\_cidr](#input\_vnet\_cidr) | CIDR for the VNet (used only when create\_network = true). | `string` | `"10.42.0.0/16"` | no |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | Name for the VNet (used only when create\_network = true). | `string` | `"vnet-azvms"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_control-node-private-ip"></a> [control-node-private-ip](#output\_control-node-private-ip) | n/a |
| <a name="output_control-node-public-ip"></a> [control-node-public-ip](#output\_control-node-public-ip) | n/a |
| <a name="output_service_private_ips"></a> [service\_private\_ips](#output\_service\_private\_ips) | n/a |
| <a name="output_service_public_ips"></a> [service\_public\_ips](#output\_service\_public\_ips) | n/a |
