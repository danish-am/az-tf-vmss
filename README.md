# az-tf-vmss
scalable Azure infrastructure using Terraform — includes Virtual Machine Scale Set (VMSS) behind a Load Balancer, autoscaling configuration, dynamic NSG rules, environment-based VM sizing, and remote backend. Ideal for production-grade web app deployments.
## 🔧 Issues Faced and How They Were Resolved

| 🔎 Issue | ✅ Resolution |
|---------|---------------|
| `main.tf` was accidentally deleted | Used `terraform state list` and `terraform state show` to inspect existing resources and manually rebuild `main.tf` |
| Public IP not reachable in browser | NSG was missing an inbound rule for port 80 (HTTP) |
| Added NSG rule via Azure Portal | Later defined the same rule in `locals.tf` to maintain Terraform control |
| Error due to incorrect protocol casing (`TCP`) | Corrected to `Tcp` (Terraform expects exact match) |
| Terraform plan showed differences | Ran `terraform refresh` to sync state, then `terraform apply` |

---

## 📘 Azure VMSS Terraform Project – Detailed Guide

This guide covers the full Terraform workflow to provision a **scalable Virtual Machine Scale Set (VMSS)** behind a **Load Balancer** in Azure, with **autoscaling**, **inbound rules**, and **remote state storage**.

---

### ✅ Step 1: Initialize Terraform and Provider Configuration

- **File:** `provider.tf`
- Declare the `azurerm` provider inside `required_providers`.
- Use `features {}` to unlock all provider capabilities.
- Terraform uses the Azure CLI (`az login`) or service principal to authenticate.

---

### ✅ Step 2: Configure Remote Backend for State Management

- Backend setup ensures state consistency across teams.
- Used Azure CLI to provision:
  - Resource Group
  - Storage Account (Standard_LRS)
  - Storage Container (e.g., `tfstate`)
- Added `backend "azurerm"` block inside `backend.tf` pointing to the container.
- Supports **state locking** and **remote collaboration**.

---

### ✅ Step 3: Create Input Variables and Local Values

- **Files:**
  - `variables.tf`: Defines reusable inputs (region, VM size, tags, subnets).
  - `terraform.tfvars`: Stores environment-specific values like `"dev"`, `"eastus"`.
  - `locals.tf`: Dynamically generates:
    - Resource names (`vmssapp-dev-rg`)
    - Subnet prefixes
    - NSG rule sets
    - Common tags

---

### ✅ Step 4: Create Resource Group

- **Resource:** `azurerm_resource_group`
- Created with a dynamic name based on environment (e.g., `vmssapp-dev-rg`).
- All Azure resources are deployed inside this RG.

---

### ✅ Step 5: Create Virtual Network and Subnets

- **Resources:**
  - `azurerm_virtual_network`
  - `azurerm_subnet`
- Created one VNet (`vmssapp-vnet`) with two subnets:
  - **App subnet** – for VMSS
  - **Mgmt subnet** – for future use like jumpbox or Bastion

---

### ✅ Step 6: Define Network Security Group (NSG) with Dynamic Rules

- **Resource:** `azurerm_network_security_group`
- Used **`dynamic` block** to create multiple rules based on `local.nsg_rules`.
- Rules:
  - `AllowLoadBalancerInbound` – for LB health probes and HTTP forwarding
  - `DenyAllInbound` – default deny rule
  - `AllowHTTPInbound` – **added later** after troubleshooting accessibility issue
- NSG associated with App Subnet using `azurerm_subnet_network_security_group_association`.

---

### ✅ Step 7: Provision Public IP and Load Balancer

- **Resources:**
  - `azurerm_public_ip` – static IP for frontend access
  - `azurerm_lb` – frontend + backend configuration
  - `azurerm_lb_backend_address_pool` – connects to VMSS instances
  - `azurerm_lb_probe` – checks health on port 80
  - `azurerm_lb_rule` – binds public IP to backend via probe
- Load balancer routes HTTP traffic to the scale set.

---

### ✅ Step 8: Deploy the Linux Virtual Machine Scale Set (VMSS)

- **Resource:** `azurerm_linux_virtual_machine_scale_set`
- Automatically scales out multiple Ubuntu VMs.
- VMSS is connected to the backend pool of the load balancer.
- Uses public SSH key from local file.
- Environment-specific VM size is chosen using `lookup(var.vm_sku_map, ...)`.
- Tags are inherited from `local.common_tags`.

---

### ✅ Step 9: Configure Autoscaling Logic

- **Resource:** `azurerm_monitor_autoscale_setting`
- Configured to:
  - **Scale out** when CPU > 80%
  - **Scale in** when CPU < 10%
- Min = 2 VMs, Max = 5 VMs
- Autoscaling linked to VMSS using its resource ID.

---

### ✅ Step 10: Output Useful Values

- **File:** `outputs.tf`
- Print key values:
  - Resource group name
  - VNet name
  - Subnet IDs
- Helps for debugging and cross-module references.

---

## 🔄 Recovery Steps After Deleting `main.tf`

1. **Checked Terraform State**:
   ```bash
   terraform state list
   ```
   Listed all resources still managed by Terraform remotely.

2. **Inspected Resource Definitions**:
   ```bash
   terraform state show <resource_name>
   ```
   Used to rebuild resource blocks in `main.tf`.

3. **Rebuilt `main.tf` Manually**:
   - Rewrote all resource definitions using output of `state show`.
   - Ensured values matched actual infra to avoid drift.

4. **Validated with Plan**:
   ```bash
   terraform plan
   ```
   Verified that Terraform detected **no changes**.

---

## 🌐 NSG Inbound Rule Fix – Detailed Recap

### Problem:
- Couldn’t access public IP of VMSS in browser.
- NSG didn’t allow traffic on port 80.

### Fix:
- Manually added rule via Azure Portal:
  - Priority: 150, Port: 80, Protocol: TCP, Action: Allow
- App became reachable ✅

### Sync with Code:
- Added the same rule in `locals.tf` under `nsg_rules`:
  ```hcl
  allow_http = {
    name        = "AllowHTTPInbound"
    priority    = 150
    direction   = "Inbound"
    access      = "Allow"
    protocol    = "Tcp" # lowercase to avoid plan errors
    source_address_prefix = "*"
    destination_address_prefix = "*"
    source_port_range     = "*"
    destination_port_range = "80"
    description = "Allow HTTP traffic from any source"
  }
  ```
- Ran:
  ```bash
  terraform refresh
  terraform plan
  terraform apply
  ```

---

## 🧪 Key Terraform Commands Used

```bash
terraform init
terraform plan
terraform apply -auto-approve

terraform state list
terraform state show <resource>
terraform refresh
