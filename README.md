Azure Internal Load Balancer Deployment with Terraform
Overview
This project provides guidance and Terraform code samples for deploying an Azure Internal Load Balancer (ILB). It supports both Standard and Basic SKUs and allows configuration for:
- Public or internal load balancing
- Backend pools
- Health probes
- Load balancing rules
- Optional inbound NAT rules

The deployment follows modular Terraform practices for multi-environment support.
Features
• Deploys Azure Load Balancer (Standard or Basic SKU)
• Configurable frontend IP (Public or Internal)
• Backend pool association with Virtual Machines or NICs
• Health probe configuration (TCP, HTTP, HTTPS)
• Load balancing rules with port mapping
• Optional inbound NAT rules
• Modular Terraform structure for environment reusability
Prerequisites
• Terraform CLI installed
• Azure CLI authenticated
• Existing Resource Group and Virtual Network
• Service principal or Managed Identity with sufficient permissions
Terraform Structure
main.tf: Core resources (Load Balancer, Frontend IP, Backend Pool, Rules)
variables.tf: Input variables for customization
outputs.tf: Useful outputs (frontend IP, backend pool ID)
modules/: Optional reusable modules (NSG, VM, etc.)
Resource Naming Convention
Resource	Name
Resource Group	az_lb_rg
Virtual Network	lb_vnet
Backend Subnet	be_subnet
Bastion Subnet	bastionSN
Network Security Group	lb_nsg
Public IP (NAT)	nat_outbound_pip
Bastion Public IP	bastion_pip
NAT Gateway	lb_nat
NICs	be_pool_nics
Bastion Host	ba_host
Internal Load Balancer	internal_lb
Backend Address Pool	be_pool
Health Probe	hp
Load Balancer Rule	lb_inbound_rule
NAT Gateway Resource	nat_gw
Example: Load Balancer Rule
resource "azurerm_lb_rule" "lb_inbound_rule" {
  loadbalancer_id                = azurerm_lb.internal_lb.id
  name                           = "lb-inbound-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  disable_outbound_snat          = true
  frontend_ip_configuration_name = "frontend-ip"
  probe_id                       = azurerm_lb_probe.hp.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.be_pool.id]
}
Security Considerations
• Ensure NSGs allow traffic to/from the Load Balancer
• Prefer Standard SKU for enhanced security and zone redundancy
• Avoid exposing backend VMs directly to the internet
• Use health probes to detect and isolate unhealthy instances
Monitoring & Logging
• Enable diagnostics using azurerm_monitor_diagnostic_setting
• Track key metrics: Packet drops, Probe status, Throughput
• Integrate with Log Analytics or Azure Monitor for insights
Importing Existing Resources
Example of importing VM extensions for Nginx:
terraform import azurerm_virtual_machine_extension.nginx_extension[0] /subscriptions/09624d5e-dd06-4d7b-9cd9-462e3f5416d0/resourceGroups/rg-lb-demo/providers/Microsoft.Compute/virtualMachines/vm-lb-demo-0/extensions/Nginx

terraform import azurerm_virtual_machine_extension.nginx_extension[1] /subscriptions/09624d5e-dd06-4d7b-9cd9-462e3f5416d0/resourceGroups/rg-lb-demo/providers/Microsoft.Compute/virtualMachines/vm-lb-demo-1/extensions/Nginx

terraform import azurerm_virtual_machine_extension.nginx_extension[2] /subscriptions/09624d5e-dd06-4d7b-9cd9-462e3f5416d0/resourceGroups/rg-lb-demo/providers/Microsoft.Compute/virtualMachines/vm-lb-demo-2/extensions/Nginx
Resources
• Terraform AzureRM Provider
• Azure Load Balancer Documentation
• Terraform Best Practices
Contributing
Contributions are welcome! Fork the repo, add improvements or new modules, and submit a PR with examples and test cases.
License
This project is licensed under the MIT License.
