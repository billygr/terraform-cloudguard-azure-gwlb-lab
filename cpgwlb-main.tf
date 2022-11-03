# Accept the agreement for the mgmt-byol for R80.40
resource "azurerm_marketplace_agreement" "gwlb-vmss-agreement" {
  count     = var.gwlb-vmss-agreement ? 0 : 1
  publisher = "checkpoint"
  offer     = "check-point-cg-r8110"
  plan      = "sg-byol"
}

# Create gwlb resource group
resource "azurerm_resource_group" "rg-gwlb-vmss" {
  name      = "rg-${var.gwlb-name}"
  location  = var.resource_group_location
}

# Create of the AZGWLB Frontend
resource "azurerm_resource_group" "rg-lb-frontend" {
  name      = "rg-lb-frontend"
  location  = var.resource_group_location
}

resource "azurerm_virtual_network" "vnet-lb-frontend" {
  name                = "vnet-lb-frontend"
  address_space       = ["192.168.0.0/22"]
  location            = azurerm_resource_group.rg-lb-frontend.location
  resource_group_name = azurerm_resource_group.rg-lb-frontend.name
}

resource "azurerm_subnet" "snet-frontend-gateways" {
  name                  = "snet-frontend-gateways"
  address_prefixes      = ["192.168.0.0/24"]
  virtual_network_name  = azurerm_virtual_network.vnet-lb-frontend.name
  resource_group_name   = azurerm_resource_group.rg-lb-frontend.name
}

resource "azurerm_resource_group_template_deployment" "template-deployment-gwlb" {
  name                = "${var.gwlb-name}-deploy"
  resource_group_name = azurerm_resource_group.rg-gwlb-vmss.name
  deployment_mode     = "Complete"

  template_content    = file("files/azure-gwlb-template.json")
  parameters_content  = <<PARAMETERS
  {
    "location": {
        "value": "${var.resource_group_location}"
    },
    "cloudGuardVersion": {
        "value": "R81.10 - Bring Your Own License"
    },
    "instanceCount": {
        "value": "${var.gwlb-vmss-min}"
    },
    "maxInstanceCount": {
        "value": "${var.gwlb-vmss-max}"
    },
    "managementServer": {
        "value": "cpmgmt"
    },
    "configurationTemplate": {
        "value": "az-${var.gwlb-name}"
    },
    "adminEmail": {
        "value": ""
    },
    "adminPassword": {
        "value": "${var.cpgw-admin-pwd}"
    },
    "authenticationType": {
        "value": "password"
    },
    "sshPublicKey": {
        "value": ""
    },
    "vmName": {
        "value": "${var.gwlb-name}"
    },
    "vmSize": {
        "value": "${var.gwlb-size}"
    },
    "sicKey": {
        "value": "${var.chkp-sic}"
    },
    "virtualNetworkName": {
        "value": "${azurerm_virtual_network.vnet-lb-frontend.name}"
    },
    "upgrading": {
        "value": "no"
    },
    "lbsTargetRGName": {
        "value": ""
    },
    "lbResourceId": {
        "value": ""
    },
    "lbTargetBEAddressPoolName": {
        "value": ""
    },
    "virtualNetworkAddressPrefix": {
        "value": "${azurerm_virtual_network.vnet-lb-frontend.address_space[0]}"
    },
    "subnet1Name": {
        "value": "${azurerm_subnet.snet-frontend-gateways.name}"
    },
    "subnet1Prefix": {
        "value": "${azurerm_subnet.snet-frontend-gateways.address_prefixes[0]}"
    },
    "subnet1StartAddress": {
        "value": "192.168.0.4"
    },
    "vnetNewOrExisting": {
        "value": "new"
    },
    "virtualNetworkExistingRGName": {
        "value": "${azurerm_virtual_network.vnet-lb-frontend.resource_group_name}"
    },
    "bootstrapScript": {
        "value": ""
    },
    "allowDownloadFromUploadToCheckPoint": {
        "value": "true"
    },
    "instanceLevelPublicIP": {
        "value": "yes"
    },
    "mgmtInterfaceOpt1": {
        "value": "eth0-private"
    },
    "mgmtIPaddress": {
        "value": ""
    },
    "diskType": {
        "value": "Standard_LRS"
    },
    "appLoadDistribution": {
        "value": "Default"
    },
    "sourceImageVhdUri": {
        "value": "noCustomUri"
    },
    "availabilityZonesNum": {
        "value": 0
    },
    "customMetrics": {
        "value": "yes"
    },
    "vxlanTunnelExternalIdentifier": {
        "value": 801
    },
    "vxlanTunnelExternalPort": {
        "value": 2001
    },
    "vxlanTunnelInternalIdentifier": {
        "value": 800
    },
    "vxlanTunnelInternalPort": {
        "value": 2000
    }
  }
  PARAMETERS 
}

# Peering from/to CP Management Hub to FrontEnd Azure GW Loadbalancer
resource "azurerm_virtual_network_peering" "vnet-cpmgmt-to-vnet-lb-frontend" {
  name = "vnet-cpmgmt-to-vnet-lb-frontend"
  resource_group_name = "rg-cpmgmt"
  virtual_network_name = azurerm_virtual_network.vnet-cpmgmt.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-lb-frontend.id
  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit = false
}
resource "azurerm_virtual_network_peering" "vnet-lb-frontend-to-vnet-cpmgmt" {
  name = "vnet-lb-frontend-to-vnet-cpmgmt"
  resource_group_name = "rg-lb-frontend"
  virtual_network_name = azurerm_virtual_network.vnet-lb-frontend.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-cpmgmt.id
  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit = false
}
