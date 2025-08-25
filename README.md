Resource Group	: 		az_lb_rg
Virtual Network	:		lb_vnet
Subnet     	:     		be_subnet
Bastion		:		bastion
NSG		:		lb_nsg
Public IP	:		outbound_pip
NAT Gateway	:		lb_nat
NIC		:		be_pool_nics
Bastion Host	:		ba_host
Internal LB	:		internal_lb
Backend Address Pool:		be_pool
Healthe Probe	:		hp
LB rule		:		lb_inbound_rule
# az-lb

Import:

terraform import azurerm_virtual_machine_extension.nginx_extension[0] /subscriptions/09624d5e-dd06-4d7b-9cd9-462e3f5416d0/resourceGroups/rg-lb-demo/providers/Microsoft.Compute/virtualMachines/vm-lb-demo-0/extensions/Nginx

terraform import azurerm_virtual_machine_extension.nginx_extension[1] /subscriptions/09624d5e-dd06-4d7b-9cd9-462e3f5416d0/resourceGroups/rg-lb-demo/providers/Microsoft.Compute/virtualMachines/vm-lb-demo-1/extensions/Nginx

terraform import azurerm_virtual_machine_extension.nginx_extension[2] /subscriptions/09624d5e-dd06-4d7b-9cd9-462e3f5416d0/resourceGroups/rg-lb-demo/providers/Microsoft.Compute/virtualMachines/vm-lb-demo-2/extensions/Nginx
