# Create a resource group using the generated random name
resource "azurerm_resource_group" "az_lb_rg" {
  name     = "rg-lb-demo"
  location = var.resource_group_location
}

# Create a Virtual Network to host the Virtual Machines
# in the Backend Pool of the Load Balancer
resource "azurerm_virtual_network" "lb_vnet" {
  name                = "lb-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.az_lb_rg.location
  resource_group_name = azurerm_resource_group.az_lb_rg.name
}

# Create a subnet in the VNet to host the VMs
# in the Backend Pool of the Load Balancer
resource "azurerm_subnet" "be_subnet" {
  name                 = "be-subnet"
  resource_group_name  = azurerm_resource_group.az_lb_rg.name
  virtual_network_name = azurerm_virtual_network.lb_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a subnet in the VNet for creating Azure Bastion
# This subnet is required for Azure Bastion to work properly

resource "azurerm_subnet" "bastionSN" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.az_lb_rg.name
  virtual_network_name = azurerm_virtual_network.lb_vnet.name
  address_prefixes     = ["10.0.2.0/27"]
}

# Create NSG and rules to control the traffic
# to and from the VMs in the Backend Pool

resource "azurerm_network_security_group" "lb_nsg" {
  name                = "lb-nsg"
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
  subnet_id                 = azurerm_subnet.be_subnet.id
  network_security_group_id = azurerm_network_security_group.lb_nsg.id
}

# PIP for Bastion
resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip"
  location            = azurerm_resource_group.az_lb_rg.location
  resource_group_name = azurerm_resource_group.az_lb_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Public IP for NAT outbound
resource "azurerm_public_ip" "nat_outbound_pip" {
  name                = "nat-outbound-pip"
  location            = azurerm_resource_group.az_lb_rg.location
  resource_group_name = azurerm_resource_group.az_lb_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NAT Gateway association

resource "azurerm_subnet_nat_gateway_association" "subnet_nat_assoc" {
  subnet_id      = azurerm_subnet.be_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}

# Create a NAT Gateway for outbound internet access of the
# VM in the Backend Pool of the Load Balancer

resource "azurerm_nat_gateway" "nat_gw" {
  name                    = "nat-gateway"
  location                = azurerm_resource_group.az_lb_rg.location
  resource_group_name     = azurerm_resource_group.az_lb_rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
}

# Associate Public IP to NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "nat_ip_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.nat_outbound_pip.id
}

# Create Network Interfaces
# The Network Interfaces will be associated with VMs created later

resource "azurerm_network_interface" "be_pool_nics" {
  count               = 3
  name                = "be-pool-nics-${count.index}"
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
  name                = "ba-host"
  location            = azurerm_resource_group.az_lb_rg.location
  resource_group_name = azurerm_resource_group.az_lb_rg.name
  sku                 = "Standard"

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.bastionSN.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

# Associate Network Interface to the Backend Pool of the Load Balancer
# The Network Interface will be used to route traffic to the VMs
# in the Backend Pool

resource "azurerm_network_interface_backend_address_pool_association" "be_pool_assoc" {
  count                   = 3
  network_interface_id    = azurerm_network_interface.be_pool_nics[count.index].id
  ip_configuration_name   = "ipconfig-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.be_pool.id
}

# Generate a random password for the VM admin users
resource "random_password" "password_for_vms" {
  length      = 10
  special     = true
  lower       = true
  upper       = true
  numeric     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
}

# Create three VMs in the Backend Pool of the Load Balancer
resource "azurerm_linux_virtual_machine" "vms_pool" {
  count                 = 3
  name                  = "${var.virtual_machine_name}-${count.index}"
  resource_group_name   = azurerm_resource_group.az_lb_rg.name
  location              = azurerm_resource_group.az_lb_rg.location
  size                  = var.vm_size
  network_interface_ids = [azurerm_network_interface.be_pool_nics[count.index].id]

  admin_username = var.vm_admin_username
  admin_password = coalesce(var.vm_admin_password, random_password.password_for_vms.result)

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.redundance_type
    name                 = "${var.disk_name}-${count.index}"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  disable_password_authentication = false
}

# Enable virtual machine extension and install Nginx
# The script will update the package list, install Nginx,
# and create a simple HTML page

resource "azurerm_virtual_machine_extension" "nginx_extension" {
  count                = 3
  name                 = "nginx-extension-${count.index}"
  virtual_machine_id   = azurerm_linux_virtual_machine.vms_pool[count.index].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = jsonencode({
    commandToExecute = "sudo apt-get update && sudo apt-get install -y nginx && echo 'Hello World from $(hostname)' | sudo tee /var/www/html/index.html && sudo systemctl restart nginx"
  })
}

# Create an Internal Load Balancer to distribute traffic to the
# Virtual Machines in the Backend Pool
resource "azurerm_lb" "internal_lb" {
  name                = "internal-lb"
  location            = azurerm_resource_group.az_lb_rg.location
  resource_group_name = azurerm_resource_group.az_lb_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "frontend-ip"
    subnet_id                     = azurerm_subnet.be_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create a Backend Address Pool for the Load Balancer
resource "azurerm_lb_backend_address_pool" "be_pool" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name            = "be-pool"
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









