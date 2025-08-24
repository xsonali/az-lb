# ========================
# Resource Group
# ========================
variable "resource_group_location" {
  description = "Azure region for all resources"
  type        = string
  default     = "AustraliaEast"
}

# ========================
# Virtual Machine
# ========================
variable "username" {
  description = "Admin username for the virtual machines"
  type        = string
  default     = "azureuser"
}

variable "password" {
  description = "Admin password for the virtual machines. If empty, a random password will be generated"
  type        = string
  default     = ""
}

variable "vm_count" {
  description = "Number of virtual machines in the backend pool"
  type        = number
  default     = 3
}

variable "redundance_type" {
  description = "Storage account type for VM disks"
  type        = string
  default     = "Standard_LRS"
}

# ========================
# Networking
# ========================
variable "nat_gateway_name" {
  description = "Name of the NAT Gateway"
  type        = string
  default     = "nat-gateway-demo"
}

variable "public_ip_count" {
  description = "Number of public IPs for NAT / Bastion"
  type        = number
  default     = 2
}
