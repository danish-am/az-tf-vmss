locals {
  resource_group_name = "vmssapp-${var.environment}-rg"
  vnet_name           = "vmssapp-vnet"
  vnet_address_space  = ["10.0.0.0/16"]

  app_subnet_name   = var.subnets.app.name
  app_subnet_prefix = var.subnets.app.address_prefix

  mgmt_subnet_name   = var.subnets.mgmt.name
  mgmt_subnet_prefix = var.subnets.mgmt.address_prefix

  public_ip_name       = "vmssapp-public-ip"
  lb_name              = "vmssapp-lb"
  lb_frontend_name     = "PublicFrontend"
  lb_backend_pool_name = "vmssapp-bepool"
  lb_probe_name        = "http-probe"
  lb_rule_name         = "http-rule"

  nsg_name          = "vmssapp-app-nsg"
  nic_name          = "vmssapp-nic"
  nic_ipconfig_name = "vmssapp-ipconfig"

  vmss_name      = "vmssapp-vmss"
  vm_size        = lookup(var.vm_sku_map, var.environment, "Standard_B1s")
  autoscale_name = "vmssapp-autoscale"

  common_tags = merge(var.tags, {
    environment = var.environment
    owner       = "danish"
  })

  nsg_rules = {
    allow_lb = {
      name                       = "AllowLoadBalancerInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
      source_port_range          = "*"
      destination_port_range     = "80"
      description                = "Allow traffic from Azure Load Balancer"
    }
    allow_http = {
      name                       = "AllowHTTPInbound"
      priority                   = 150
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      source_port_range          = "*"
      destination_port_range     = "80"
      description                = "Allow HTTP traffic from any source"
    }
    deny_all = {
      name                       = "DenyAllInbound"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      description                = "Deny all inbound traffic"
    }
  }
}