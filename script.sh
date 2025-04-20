!/bin/bash

# Importing Azure resources into Terraform state

terraform import azurerm_resource_group.main /subscriptions/<subscription_id>/resourceGroups/vmssapp-dev-rg

terraform import azurerm_virtual_network.main /subscriptions/<subscription_id>/resourceGroups/vmssapp-dev-rg/providers/Microsoft.Network/virtualNetworks/vmssapp-vnet

terraform import azurerm_subnet.app /subscriptions/<subscription_id>/resourceGroups/vmssapp-dev-rg/providers/Microsoft.Network/virtualNetworks/vmssapp-vnet/subnets/vmssapp-app-subnet

terraform import azurerm_subnet.mgmt /subscriptions/<subscription_id>/resourceGroups/vmssapp-dev-rg/providers/Microsoft.Network/virtualNetworks/vmssapp-vnet/subnets/vmssapp-mgmt-subnet

terraform import azurerm_network_security_group.app_nsg /subscriptions/<subscription_id>/resourceGroups/vmssapp-dev-rg/providers/Microsoft.Network/networkSecurityGroups/vmssapp-app-nsg

terraform import azurerm_subnet_network_security_group_association.app_subnet_assoc /subscriptions/<subscription_id>/resourceGroups/vmssapp-dev-rg/providers/Microsoft.Network/virtualNetworks/vmssapp-vnet/subnets/vmssapp-app-subnet

terraform import azurerm_public_ip.lb_public_ip /subscriptions/<subscription_id>/resourceGroups/vmssapp-dev-rg/providers/Microsoft.Network/publicIPAddresses/vmssapp-public-ip

terraform import azurerm_lb.main /subscriptions/<subscription_id>/resourceGroups/vmssapp-dev-rg/providers/Microsoft.Network/loadBalancers/vmssapp-lb

terraform import azurerm_lb_backend_address_pool.main /subscriptions/<subscription_id>/resourceGroups/vmssapp-dev-rg/providers/Microsoft.Network/loadBalancers/vmssapp-lb/backendAddressPools/vmssapp-bepool

terraform import azurerm_lb_probe.http_probe /subscriptions/<subscription_id>/resourceGroups/vmssapp-dev-rg/providers/Microsoft.Network/loadBalancers/vmssapp-lb/probes/http-probe

terraform import azurerm_lb_rule.http /subscriptions/<subscription_id>/resourceGroups/vmssapp-dev-rg/providers/Microsoft.Network/loadBalancers/vmssapp-lb/loadBalancingRules/http-rule

terraform import azurerm_linux_virtual_machine_scale_set.vmss /subscriptions/<subscription_id>/resourceGroups/vmssapp-dev-rg/providers/Microsoft.Compute/virtualMachineScaleSets/vmssapp-vmss


terraform import azurerm_monitor_autoscale_setting.vmss_autoscale /subscriptions/<subscription_id>/resourceGroups/vmssapp-dev-rg/providers/Microsoft.Insights/autoScaleSettings/vmssapp-autoscale
