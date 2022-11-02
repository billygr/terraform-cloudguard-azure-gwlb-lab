# Accept the agreement for the mgmt-byol for R80.40
resource "azurerm_marketplace_agreement" "cpmgmt-agreement" {
  count     = var.mgmt-sku-enabled ? 0 : 1
  publisher = "checkpoint"
  offer     = "check-point-cg-${var.mgmt-version}"
  plan      = var.mgmt-sku
}

# Create management resource group
resource "azurerm_resource_group" "rg-cpmgmt" {
  name      = "rg-cpmgmt"
  location  = var.resource_group_location
}

# Create virtual network
resource "azurerm_virtual_network" "vnet-cpmgmt" {
  name                = "vnet-cpmgmt"
  address_space       = ["172.16.0.0/12"]
  location            = azurerm_resource_group.rg-cpmgmt.location
  resource_group_name = azurerm_resource_group.rg-cpmgmt.name
}

# Create subnet
resource "azurerm_subnet" "snet-cpmgmt" {
  name                 = "snet-cpmgmt"
  resource_group_name  = azurerm_resource_group.rg-cpmgmt.name
  virtual_network_name = azurerm_virtual_network.vnet-cpmgmt.name
  address_prefixes     = ["172.16.1.0/24"]
}

# Create NSG for the management
resource "azurerm_network_security_group" "nsg-cpmgmt" {
  name      = "nsg-cpmgmt"
  location  = azurerm_resource_group.rg-cpmgmt.location
  resource_group_name = azurerm_resource_group.rg-cpmgmt.name
}

# Create the NSG rules for the management
resource "azurerm_network_security_rule" "nsg-ckpmgmt-rl-ssh" {
  priority  = 100
  name      = "ssh-access"
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.my-pub-ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-cpmgmt.name
  network_security_group_name = azurerm_network_security_group.nsg-cpmgmt.name
}
resource "azurerm_network_security_rule" "nsg-ckpmgmt-rl-https" {
  priority  = 110
  name      = "https-access"
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = var.my-pub-ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-cpmgmt.name
  network_security_group_name = azurerm_network_security_group.nsg-cpmgmt.name
}
resource "azurerm_network_security_rule" "nsg-ckpmgmt-rl-smartconsole" {
  priority  = 120
  name      = "smartconsole-access"
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range           = "*"
  destination_port_ranges     = ["18190","19009"]
  source_address_prefix       = var.my-pub-ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-cpmgmt.name
  network_security_group_name = azurerm_network_security_group.nsg-cpmgmt.name
}
resource "azurerm_network_security_rule" "nsg-ckpmgmt-rl-exposedsrvc" {
  priority  = 130
  name      = "log-ICA-CRL-Policy-access"
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range           = "*"
  destination_port_ranges     = ["257","18210","18264","18191"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-cpmgmt.name
  network_security_group_name = azurerm_network_security_group.nsg-cpmgmt.name
}

# Create Public IP
resource "azurerm_public_ip" "pip-cpmgmt" {
    name      = "pip-cpmgmt"
    location  = azurerm_resource_group.rg-cpmgmt.location
    resource_group_name = azurerm_resource_group.rg-cpmgmt.name
    allocation_method   = "Dynamic"
}
# Create NIC
resource "azurerm_network_interface" "nic-cpmgmt" {
    name                = "nic-cpmgmt"
    location            = azurerm_resource_group.rg-cpmgmt.location
    resource_group_name = azurerm_resource_group.rg-cpmgmt.name
    enable_ip_forwarding = "false"
  
	ip_configuration {
      name      = "nic-cpmgmt-eth0-config"
      subnet_id = azurerm_subnet.snet-cpmgmt.id
      primary   = true  
	  private_ip_address = "172.16.1.4"
      private_ip_address_allocation = "Static"
	  public_ip_address_id = azurerm_public_ip.pip-cpmgmt.id
    }
}
resource "azurerm_network_interface_security_group_association" "nsg-cpmgmt" {
  network_interface_id      = azurerm_network_interface.nic-cpmgmt.id
  network_security_group_id = azurerm_network_security_group.nsg-cpmgmt.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.rg-cpmgmt.name
    }
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "ckp-storageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.rg-cpmgmt.name
    location                    = azurerm_resource_group.rg-cpmgmt.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
}

# Create virtual machine
resource "azurerm_virtual_machine" "vm-cpmgmt" {
    name                  = "vm-cpmgmt"
    location              = azurerm_resource_group.rg-cpmgmt.location
    resource_group_name   = azurerm_resource_group.rg-cpmgmt.name
    network_interface_ids = [azurerm_network_interface.nic-cpmgmt.id]
    primary_network_interface_id = azurerm_network_interface.nic-cpmgmt.id
    vm_size               = var.mgmt-size
    
    # parameters = { "installationType" = "management" }

    storage_os_disk {
        name              = "disk-cpmgmt"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }
    storage_image_reference {
        publisher = "checkpoint"
        offer     = "check-point-cg-${var.mgmt-version}"
        sku       = var.mgmt-sku
        version   = "latest"
    }
    plan {
        name      = var.mgmt-sku
        publisher = "checkpoint"
        product   = "check-point-cg-${var.mgmt-version}"
    }
    os_profile {
        computer_name   = "vm-cpmgmt"
		admin_username  = "azureuser"
        admin_password  = var.cpmgmt-admin-pwd
        custom_data     = file("customdata.sh")
    }
    os_profile_linux_config {
        disable_password_authentication = false
    }
    boot_diagnostics {
        enabled     = "true"
        storage_uri = azurerm_storage_account.ckp-storageaccount.primary_blob_endpoint
    }
}
