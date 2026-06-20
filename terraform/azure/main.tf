# main.tf
# Core Azure infrastructure - resource group, networking, and a Linux VM

# Resource Group - logical container for all Azure resources
resource "azurerm_resource_group" "homelab" {
  name     = "${var.prefix}-rg"
  location = var.location
}

# Virtual Network - private network in Azure
resource "azurerm_virtual_network" "homelab" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.homelab.name
  location            = azurerm_resource_group.homelab.location
  address_space       = ["10.0.0.0/16"]
}

# Subnet - segment of the virtual network
resource "azurerm_subnet" "homelab" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.homelab.name
  virtual_network_name = azurerm_virtual_network.homelab.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP - so we can SSH into the VM
resource "azurerm_public_ip" "homelab" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.homelab.name
  location            = azurerm_resource_group.homelab.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Security Group - firewall rules
resource "azurerm_network_security_group" "homelab" {
  name                = "${var.prefix}-nsg"
  resource_group_name = azurerm_resource_group.homelab.name
  location            = azurerm_resource_group.homelab.location

  # Allow SSH from anywhere - restrict to your IP in production
  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Interface - connects the VM to the network
resource "azurerm_network_interface" "homelab" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.homelab.name
  location            = azurerm_resource_group.homelab.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.homelab.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.homelab.id
  }
}

# Associate NSG with network interface
resource "azurerm_network_interface_security_group_association" "homelab" {
  network_interface_id      = azurerm_network_interface.homelab.id
  network_security_group_id = azurerm_network_security_group.homelab.id
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "homelab" {
  name                = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.homelab.name
  location            = azurerm_resource_group.homelab.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.homelab.id
  ]

  # SSH key authentication - no passwords
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Ubuntu 24.04 LTS - same as your homelab nodes
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
