#Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  address_space       = local.vnet_address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# Subnets
resource "azurerm_subnet" "app" {
  name                 = local.app_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.app_subnet_prefix]
}

resource "azurerm_subnet" "mgmt" {
  name                 = local.mgmt_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.mgmt_subnet_prefix]
}

# Network Security Group
resource "azurerm_network_security_group" "app_nsg" {
  name                = local.nsg_name
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  dynamic "security_rule" {
    for_each = local.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      description                = security_rule.value.description
    }
  }
}

# NSG Association
resource "azurerm_subnet_network_security_group_association" "app_subnet_assoc" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# Public IP
resource "azurerm_public_ip" "lb_public_ip" {
  name                = local.public_ip_name
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# Load Balancer
resource "azurerm_lb" "main" {
  name                = local.lb_name
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  tags                = local.common_tags

  frontend_ip_configuration {
    name                 = local.lb_frontend_name
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

# Backend Pool
resource "azurerm_lb_backend_address_pool" "main" {
  name            = local.lb_backend_pool_name
  loadbalancer_id = azurerm_lb.main.id
}

# Health Probe
resource "azurerm_lb_probe" "http_probe" {
  name                = local.lb_probe_name
  loadbalancer_id     = azurerm_lb.main.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Load Balancer Rule
resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = local.lb_frontend_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
  disable_outbound_snat          = false
  enable_floating_ip             = false
  enable_tcp_reset               = false
  idle_timeout_in_minutes        = 4
  load_distribution              = "Default"
}

# Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = var.vmss_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = local.vm_size
  instances           = var.instance_count
  admin_username      = var.admin_username
  upgrade_mode        = "Manual"
  overprovision       = true

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18_04-lts-gen2"
    version   = "latest"
  }


  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = local.nic_name
    primary = true
    ip_configuration {
      name                                   = local.nic_ipconfig_name
      primary                                = true
      subnet_id                              = azurerm_subnet.app.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.main.id]
    }
  }

  extension {
    name                 = "nginx"
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.1"
    settings = jsonencode({
      commandToExecute = "sudo apt update && sudo apt install -y nginx"
    })
  }

  tags = local.common_tags
}

# Autoscale Setting
resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = local.autoscale_name
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id
  enabled             = true
  tags                = local.common_tags

  profile {
    name = "AutoScaleProfile"
    capacity {
      minimum = 2
      maximum = 5
      default = 2
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_namespace   = "Microsoft.Compute/virtualMachineScaleSets"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 80
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_namespace   = "Microsoft.Compute/virtualMachineScaleSets"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 10
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M"
      }
    }
  }
}
