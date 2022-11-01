resource "random_pet" "rg_name-serviceB" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg-serviceB" {
  location = var.resource_group_location
  name     = random_pet.rg_name-serviceB.id
}

# Create virtual network
resource "azurerm_virtual_network" "vnet-serviceB" {
  name                = "vnet-serviceB"
  address_space       = ["10.0.2.0/23"]
  location            = azurerm_resource_group.rg-serviceB.location
  resource_group_name = azurerm_resource_group.rg-serviceB.name
}

# Create subnet
resource "azurerm_subnet" "snet-serviceB" {
  name                 = "snet-serviceB"
  resource_group_name  = azurerm_resource_group.rg-serviceB.name
  virtual_network_name = azurerm_virtual_network.vnet-serviceB.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "pip-serviceB" {
  name                = "pip-serviceB"
  location            = azurerm_resource_group.rg-serviceB.location
  resource_group_name = azurerm_resource_group.rg-serviceB.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg-serviceB" {
  name                = "nsg-serviceB"
  location            = azurerm_resource_group.rg-serviceB.location
  resource_group_name = azurerm_resource_group.rg-serviceB.name

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
resource "azurerm_network_interface" "nic-serviceB" {
  name                = "nic-serviceB"
  location            = azurerm_resource_group.rg-serviceB.location
  resource_group_name = azurerm_resource_group.rg-serviceB.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.snet-serviceB.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-serviceB.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsg-association-serviceB" {
  network_interface_id      = azurerm_network_interface.nic-serviceB.id
  network_security_group_id = azurerm_network_security_group.nsg-serviceB.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id-serviceB" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg-serviceB.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "st-serviceB" {
  name                     = "diag${random_id.random_id-serviceB.hex}"
  location                 = azurerm_resource_group.rg-serviceB.location
  resource_group_name      = azurerm_resource_group.rg-serviceB.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "vm-serviceB" {
  name                  = "vm-ServiceB"
  location              = azurerm_resource_group.rg-serviceB.location
  resource_group_name   = azurerm_resource_group.rg-serviceB.name
  network_interface_ids = [azurerm_network_interface.nic-serviceB.id]
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

  computer_name                   = "vm-serviceB"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.st-serviceB.primary_blob_endpoint
  }
}
