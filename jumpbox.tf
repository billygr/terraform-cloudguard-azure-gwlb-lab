# Create resource group jumpbox
resource "azurerm_resource_group" "rg-jumpbox" {
  name      = "rg-jumpbox"
  location  = var.resource_group_location
}

# Create virtual network
resource "azurerm_virtual_network" "vnet-jumpbox" {
  name                = "vnet-jumpbox"
  address_space       = ["172.18.0.0/23"]
  location            = azurerm_resource_group.rg-jumpbox.location
  resource_group_name = azurerm_resource_group.rg-jumpbox.name
}

# Create subnet
resource "azurerm_subnet" "snet-jumpbox" {
  name                 = "snet-jumpbox"
  resource_group_name  = azurerm_resource_group.rg-jumpbox.name
  virtual_network_name = azurerm_virtual_network.vnet-jumpbox.name
  address_prefixes     = ["172.18.0.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "pip-jumpbox" {
  name                = "pip-jumpbox"
  location            = azurerm_resource_group.rg-jumpbox.location
  resource_group_name = azurerm_resource_group.rg-jumpbox.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg-jumpbox" {
  name                = "nsg-jumpbox"
  location            = azurerm_resource_group.rg-jumpbox.location
  resource_group_name = azurerm_resource_group.rg-jumpbox.name

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
resource "azurerm_network_interface" "nic-jumpbox" {
  name                = "nic-jumpbox"
  location            = azurerm_resource_group.rg-jumpbox.location
  resource_group_name = azurerm_resource_group.rg-jumpbox.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.snet-jumpbox.id
    private_ip_address            = "172.18.0.4"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.pip-jumpbox.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsg-association-jumpbox" {
  network_interface_id      = azurerm_network_interface.nic-jumpbox.id
  network_security_group_id = azurerm_network_security_group.nsg-jumpbox.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id-jumpbox" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg-jumpbox.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "st-jumpbox" {
  name                     = "diag${random_id.random_id-jumpbox.hex}"
  location                 = azurerm_resource_group.rg-jumpbox.location
  resource_group_name      = azurerm_resource_group.rg-jumpbox.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "vm-jumpbox" {
  name                  = "vm-jumpbox"
  location              = azurerm_resource_group.rg-jumpbox.location
  resource_group_name   = azurerm_resource_group.rg-jumpbox.name
  network_interface_ids = [azurerm_network_interface.nic-jumpbox.id]
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

  computer_name                   = "vm-jumpbox"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.st-jumpbox.primary_blob_endpoint
  }
}
