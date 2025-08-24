# Create a resource group using the generated random name
resource "azurerm_resource_group" "az_lb_rg" {
  name     = "rg-lb-demo"
  location = var.resource_group_location
}

# Create a Virtual Network to host the Virtual Machines
# in the Backend Pool of the Load Balancer
resource "azurerm_virtual_network" "lb_vnet" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.az_lb_rg.location
  resource_group_name = azurerm_resource_group.az_lb_rg.name
}

# Create a subnet in the VNet to host the VMs
# in the Backend Pool of the Load Balancer
resource "azurerm_subnet" "be_subnet" {
  name	                = var.subnet_name
  resource_group_name   = azurerm_resource_group.az_lb_rg.name
  virtual_network_name  = azurerm_virtual_network.lb_vnet.name
  address_prefixes      = ["10.0.1.0/24"]
}

# Create a subnet in the VNet for creating Azure Bastion
# This subnet is required for Azure Bastion to work properly

resource "azurerm_subnet" "bastion" {
  name                  = "AzureBastionSubnet"
  resource_group_name   = azurerm_resource_group.az_lb_rg.name
  virtual_network_name  = azurerm_virtual_network.lb_vnet.name
  address_prefixes      = ["10.0.2.0/27"]
}

# Create NSG and rules to control the traffic
# to and from the VMs in the Backend Pool

resource "azurerm_network_security_group" "lb_nsg" {
  name                = var.network_security_group_name
  location            = azurerm_resource_group.az_lb_rg.location
  resource_group_name = azurerm_resource_group.az_lb_rg.name
    
  security_rule {
    name                       = "ssh"
	priority                   = 1022
	direction                  = "Inbound"
	access                     = "Allow"
	protocol                   = "Tcp"
	source_port_range          = "*"
	destination_port_range     = "22"
	source_address_prefix      = "*"
	destination_address_prefix = "10.0.1.0/24"
  }
  
  security_rule {
    name                       = "web"
	priority                   = 1080
	direction                  = "Inbound"
	access                     = "Allow"
	protocol                   = "Tcp"
	source_port_range          = "*"
	destination_port_range     = "80"
	source_address_prefix      = "*"
	destination_address_prefix = "10.0.1.0/24"
  }
}

# Associate the NSG to the subnet to allow the
# NSG to control the traffic to and from the subnet

resource "azurerm_subnet_network_security_group_association" "be_subnet_nsg_assoc" {
  subnet_id                   = azurerm_subnet.be_subnet.id
  network_security_group_id   = azurerm_network_security_group.lb_nsg.id
}

# Create Public IPs to reute traffic from the Load Balancer
# to the VMs in the Backend Pool

resource "azurerm_public_ip" "outbound_pip" {
  count                = 2
  name                 = "${var.public_ip_name}-${count.index}"
  location             = azurerm_resource_group.az_lb_rg.location
  resource_group_name  = azurerm_resource_group.az_lb_rg.name
  allocation_method    = "Static"
  sku                  = "Standard"
}

# Create a NAT Gateway for outbound internet access of the
# VM in the Backend Pool of the Load Balancer

resource "azurerm_nat_gateway" "lb_nat" {
  name               = var.nat_gateway
  location           = azurerm_resource_group.az_lb_rg.location
  resource_group_name = azurerm_resource_group.az_lb_rg.name
  sku_name            = "Standard"
}

# Associate one of the Public IPs to the NAT Gateway to route
# traffic from the Virtual Machines to the internet

resource "azurerm_nat_gateway_public_ip_association" "nat_pip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.lb_nat.id
  public_ip_address_id = azurerm_public_ip.outbound_pip[0].id
}

# Create Network Interfaces
# The Network Interfaces will be associated with VMs created later

resource "azurerm_network_interface" "be_pool_nics" {
  count               = 3
  name                = "${var.network_interface_name}-${count.index}"
  location            = azurerm_resource_group.az_lb_rg.location
  resource_group_name = azurerm_resource_group.az_lb_rg.name
  
  ip_configuration {
    name                          = "ipconfig-${count.index}"
	subnet_id                     = azurerm_subnet.be_subnet.id
	private_ip_address_allocation = "Dynamic"
	primary                       = true
  }
}

# Create Azure Bastion for accessing the VMs
# The Bastion Host will be used to acess the VMs
# in the Backend Pool of the Load Balancer

resource "azurerm_bastion_host" "ba_host" {
  name                  = var.bastion_name
  location              = azurerm_resource_group.az_lb_rg.location
  resource_group_name   = azurerm_resource_group.az_lb_rg.name
  sku                   = "Standard"
  
  ip_configuration {
    name                   = "ipconfig"
	subnet_id              = azurerm_subnet.bastion.id
	public_ip_address_id   = azurerm_public_ip.outbound_pip[1].id
  }
}

# Associate Network Interface to the Backend Pool of the Load Balancer
# The Network Interface will be used to route traffic to the VMs
# in the Backend Pool

resource "azurerm_network_interface_backend_address_pool_association" "be_pool_assoc" {
  count                    = 3
  network_interface_id     = azurerm_network_interface.be_pool_nics[count.index].id
  ip_configuration_name    = "ipconfig-${count.index}"
  backend_address_pool_id  = azurerm_backend_address_pool.be_pool.id
}

# Generate a random password for the VM admin users
resource "random_password" "password_for_vms" {
  length  = 10
  special = true
  lower   = true
  numeric = true
}

# Create three VMs in the Backend Pool of the Load Balancer
resource "azurerm_virtual_machine" "vms_pool" {
  count                      = 3
  name                       = "${var.virtual_machine_name}-${count.index}"
  location                   = azurerm_resource_group.az_lb_rg.location
  resource_group_name        = azurerm_resource_group.az_lb_rg.name
  network_interface_ids      = [azurerm_network_interface.be_pool_nics[count.index].id]
  
  os_disk {
    name                     = "${var.disk_name}-${count.index}"
	caching                  = "ReadWrite"
	storage_account_type     = var.redundance_type
  }
  
  source_image_reference {
    publisher = "Canonical"
	offer     = "0001-com-ubuntu-server-jammy"
	sku       = "22.04-lts-gen2"
	version   = "latest"
  }
  
  admin_username                  = var.username
  admin_password                  = coalesce(var.password, random_password.password_for_vms.result)
  disable_password_authentication = false
}

# Enable virtual machine extension and install Nginx
# The script will update the package list, install Nginx,
# and create a simple HTML page

resource "azurerm_virtual_machine_extension" "nginx_extension" {
  count                = 3
  name                 = "Nginx"
  virtual_machine_id   = azurerm_virtual_machine.vms_pool[count.index].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  
  settings = <<SETTINGS
{
"commandToExecute": "sudo apt-get update && sudo apt-get install nginx -y && echo \"Hello World from $(hostname)\" > /var/www/html/index.html && sudo systemctl restart nginx" 
}
SETTINGS

}

# Create an Internal Load Balancer to distribute traffic to the
# Virtual Machines in the Backend Pool
resource "azurerm_lb" "internal_lb" {
  name                 = var.load_balancer_name
  location             = azurerm_resource_group.az_lb_rg.location
  resource_group_name  = azurerm_resource_group.az_lb_rg.name
  sku                  = "Standard"
  
  frontend_ip_configuration {
    name                          = "frontend-ip"
	subnet_id                     = azurerm_subnet.be_subnet.id
	private_ip_address_allocation = "Dynamic"
  }
}

# Create a Backend Address Pool for the Load Balancer
resource "azurerm_lb_backend_address_pool" "be_pool" {
  load_balancer_id = azurerm_lb.internal_lb.id
  name             = "be-pool"
}

# Create a Load Balancer Probe to check the health of the
# Virtual Machines in the Backend Pool
resource "azurerm_lb_probe" "hp" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name            = "health-probe"
  port            = 80
}

# Create a Load Balancer Rule to define how traffic will be
# distributed to the VMs in the Backend Pool
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

	
	  

  
  
    
  
  
  
  