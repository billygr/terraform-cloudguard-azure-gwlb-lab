resource "random_pet" "rg_name-serviceA" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg-serviceA" {
  location = var.resource_group_location
  name     = random_pet.rg_name-serviceA.id
}

# Create virtual network
resource "azurerm_virtual_network" "vnet-serviceA" {
  name                = "vnet-serviceA"
  address_space       = ["10.0.0.0/23"]
  location            = azurerm_resource_group.rg-serviceA.location
  resource_group_name = azurerm_resource_group.rg-serviceA.name
}

# Create subnet
resource "azurerm_subnet" "snet-serviceA" {
  name                 = "snet-serviceA"
  resource_group_name  = azurerm_resource_group.rg-serviceA.name
  virtual_network_name = azurerm_virtual_network.vnet-serviceA.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "pip-serviceA" {
  name                = "pip-serviceA"
  location            = azurerm_resource_group.rg-serviceA.location
  resource_group_name = azurerm_resource_group.rg-serviceA.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg-serviceA" {
  name                = "nsg-serviceA"
  location            = azurerm_resource_group.rg-serviceA.location
  resource_group_name = azurerm_resource_group.rg-serviceA.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic-serviceA" {
  name                = "nic-serviceA"
  location            = azurerm_resource_group.rg-serviceA.location
  resource_group_name = azurerm_resource_group.rg-serviceA.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.snet-serviceA.id
    private_ip_address            = "10.0.1.4"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.pip-serviceA.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsg-association-serviceA" {
  network_interface_id      = azurerm_network_interface.nic-serviceA.id
  network_security_group_id = azurerm_network_security_group.nsg-serviceA.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id-serviceA" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg-serviceA.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "st-serviceA" {
  name                     = "diag${random_id.random_id-serviceA.hex}"
  location                 = azurerm_resource_group.rg-serviceA.location
  resource_group_name      = azurerm_resource_group.rg-serviceA.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "vm-serviceA" {
  name                  = "vm-ServiceA"
  location              = azurerm_resource_group.rg-serviceA.location
  resource_group_name   = azurerm_resource_group.rg-serviceA.name
  network_interface_ids = [azurerm_network_interface.nic-serviceA.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "vm-serviceA"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.st-serviceA.primary_blob_endpoint
  }
}
