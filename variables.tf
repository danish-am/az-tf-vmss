variable "location" {
  type    = string
  default = "westeurope"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "subnets" {
  type = map(object({
    name           = string
    address_prefix = string
  }))
  default = {
    app = {
      name           = "vmssapp-app-subnet"
      address_prefix = "10.0.1.0/24"
    }
    mgmt = {
      name           = "vmssapp-mgmt-subnet"
      address_prefix = "10.0.2.0/24"
    }
  }
}

variable "vmss_name" {
  type    = string
  default = "vmssapp-vmss"
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "vm_sku_map" {
  type = map(string)
  default = {
    dev   = "Standard_B1s"
    stage = "Standard_B2s"
    prod  = "Standard_B2ms"
  }
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "admin_ssh_public_key" {
  type        = string
  description = "Your SSH public key"
}

variable "tags" {
  type = map(string)
  default = {
    project = "vmss-loadbalancer"
  }
}
