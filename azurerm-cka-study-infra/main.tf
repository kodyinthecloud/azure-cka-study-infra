module "az_vms" {
  source              = "/Users/kodybaker/IdeaProjects/azure--cka-study-infra"


  resource_group_name = "rg-demo"
  location            = "eastus"

  # Option A: create a fresh VNet/Subnet
  create_network = true
  vnet_name      = "vnet-demo"
  vnet_cidr      = "10.60.0.0/16"
  subnet_name    = "subnet-demo"
  subnet_cidr    = "10.60.1.0/24"

  # Option B (instead): use existing
  # subnet_id = "/subscriptions/xxxx/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-x/subnets/app"

  admin_username = "kody"
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  service_nodes = {
    service-1 = {}
    service-2 = {}
  }

  # optional env passed to scripts
  control_script_env = {
    CONTROL_FOO = "bar"
  }
  service_script_env = {
    SVC_ROLE = "api"
  }

  tags = {
    project = "demo"
    env     = "dev"
  }
}
