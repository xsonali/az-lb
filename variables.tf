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
variable "vm_admin_username" {
  type        = string
  description = "Admin username for the Linux VM"
}

variable "vm_admin_password" {
  type        = string
  description = "Admin password for the Linux VM"
  sensitive   = true
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

variable "virtual_machine_name" {
  description = "Base name for the Virtual Machines"
  type        = string
  default     = "vm-lb-demo"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B1s" # Or your preferred VM size
}

variable "disk_name" {
  description = "Base name for VM disks"
  type        = string
  default     = "myDisk"
}
