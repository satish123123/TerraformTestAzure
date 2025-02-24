terraform {
  backend "azurerm" {
    resource_group_name  = "satishdevops-infra"
    storage_account_name = "satishdevopststate"
    container_name       = "tstate"
    key                  = "BwN4SKWhwD10Z3oxxs4dQrXBerhVPLe76RrcadzosZffg0lzrG0Y5bktPWPC4j8RsNCuQtHqpt/4+AStxl2m+g=="
  }

  required_providers {
    azurerm = {
      # Specify what version of the provider we are going to utilise
      source  = "hashicorp/azurerm"
      version = ">= 2.4.1"
    }
  }
}
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
data "azurerm_client_config" "current" {}
# Create our Resource Group - satishdevops-RG
resource "azurerm_resource_group" "rg" {
  name     = "satishdevops-app01"
  location = "UK South"
}
# Create our Virtual Network - satishdevops-VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "satishdevopsvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Create our Subnet to hold our VM - Virtual Machines
resource "azurerm_subnet" "sn" {
  name                 = "VM"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
# Create our Azure Storage Account - satishdevopssa
resource "azurerm_storage_account" "satishdevopssa" {
  name                     = "satishdevopssa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "satishdevopsenv122newdevops"
  }
}
# Create our vNIC for our VM and assign it to our Virtual Machines Subnet
resource "azurerm_network_interface" "vmnic" {
  name                = "satishdevopsvm01nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create our Virtual Machine - satishdevops-VM01
resource "azurerm_virtual_machine" "vm" {
  name                  = "devopsvm01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_B2s"
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }
  storage_os_disk {
    name              = "satishdevopsvm01os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "devopsvm01"
    admin_username = "satishdevops"
    admin_password = "Password123$"
  }
  os_profile_windows_config {
  }
}
