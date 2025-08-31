Azure Internal Load Balancer Deployment with Terraform
________________________________________
Overview 
This document provides guidance for deploying an Azure Internal Load Balancer using Terraform. It supports both Standard and Basic SKUs and includes configuration for public or internal load balancing, backend pools, health probes, and load balancing rules.
________________________________________
Features
•	Deploys Azure Load Balancer (Standard or Basic SKU)
•	Configurable frontend IP (Public or Internal)
•	Backend pool association with virtual machines or NICs
•	Health probe configuration (TCP, HTTP, HTTPS)
•	Load balancing rules with port mapping
•	Optional inbound NAT rules
•	Modular Terraform structure for multi-environment support
________________________________________
Prerequisites
•	Terraform CLI installed
•	Azure CLI authenticated
•	Existing resource group and virtual network
•	Service principal or managed identity with appropriate permissions
________________________________________
Terraform Structure
•	main.tf: Core resources (Load Balancer, frontend IP, backend pool, rules)
•	variables.tf: Input variables for customization
•	outputs.tf: Useful outputs (e.g., frontend IP, backend pool ID)
•	modules/: Optional reusable modules for NSG, VM, etc.
________________________________________
Key logical name of the resources
	                         	
Resource Group		    : 		az_lb_rg
Virtual Network		    :		lb_vnet
Backend Subnet 	      :     		be_subnet
Bastion			          :		bastionSN
NSG			              :		lb_nsg
Public IP NAT		      :		nat_outbound_pip
Bastion PIP		        :		bastion_pip
NAT Gateway		        :		lb_nat
NIC			              :		be_pool_nics
Bastion Host		      :		ba_host
Internal LB		        :		internal_lb
Backend Address Pool	:		be_pool
Healthe Probe		      :		hp
LB rule			          :		lb_inbound_rule
NAT GW		            :		nat_gw		
		
		
		
		
		
________________________________________
resource "azurerm_lb_rule" "lb_inbound_rule" {
  loadbalancer_id                     = azurerm_lb.internal_lb.id
  name                                = "lb-inbound-rule"
  protocol                            = "Tcp"
  frontend_port                       = 80
  backend_port                        = 80
  disable_outbound_snat               = true
  frontend_ip_configuration_name      = "frontend-ip"
  probe_id                            = azurerm_lb_probe.hp.id
  backend_address_pool_ids            = [azurerm_lb_backend_address_pool.be_pool.id]
}
________________________________________
Security Considerations
•	Ensure NSGs allow traffic to/from the Load Balancer
•	Use Standard SKU for better security and zone redundancy
•	Avoid exposing backend VMs directly to the internet
•	Use health probes to detect and isolate unhealthy instances
________________________________________
Monitoring & Logging
•	Enable diagnostics via azurerm_monitor_diagnostic_setting
•	Track metrics like packet drops, probe status, and throughput
•	Integrate with Log Analytics or Azure Monitor for insights
________________________________________
Resources
•	Terraform AzureRM Provider
•	Azure Load Balancer Documentation
•	Terraform Best Practices
________________________________________
Contributing
Feel free to fork this documentation and submit improvements or new modules. Please follow the existing structure and include examples or test cases where applicable.
________________________________________
License
This project is licensed under the MIT License.

