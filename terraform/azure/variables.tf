# variables.tf
# Input variables for the Azure infrastructure

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "West Europe"  # Amsterdam datacentre
}

variable "prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "homelab"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "k0r4y"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_D2s_v6"
}
