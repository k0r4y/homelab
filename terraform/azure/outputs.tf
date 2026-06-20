# outputs.tf
# Values displayed after terraform apply completes

output "resource_group_name" {
  description = "Name of the Azure resource group"
  value       = azurerm_resource_group.homelab.name
}

output "vm_public_ip" {
  description = "Public IP address of the VM - use this to SSH in"
  value       = azurerm_public_ip.homelab.ip_address
}

output "ssh_command" {
  description = "Command to SSH into the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.homelab.ip_address}"
}
