@description('Name of the Azure Firewall within the vHub A')
param azureFirewall_Name string

@description('Sku name of the Azure Firewall.  Allowed values are Basic, Standard, and Premium')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param azureFirewall_SKU string

@description('Name of the Azure Firewall Policy')
param azureFirewallPolicy_ID string

@description('Resource ID of the Azure Firewall Subnet.  Note: The subnet name must be "AzureFirewallSubnet')
param azureFirewall_Subnet_ID string

@description('Resource ID of the Azure Firewall Management Subnet.  Note: The subnet name must be "AzureFirewallManagementSubnet')
param azureFirewall_ManagementSubnet_ID string = ''

param useForceTunneling bool = false

param tagValues object = {}

var location = resourceGroup().location

resource azureFirewall_PIP 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: '${azureFirewall_Name}_PIP'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
  tags: tagValues
}

resource azureFirewall_Management_PIP 'Microsoft.Network/publicIPAddresses@2022-11-01' = if (useForceTunneling) {
  name: '${azureFirewall_Name}_Management_PIP'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
  tags: tagValues
}

resource azureFirewall 'Microsoft.Network/azureFirewalls@2022-11-01' = {
  name: azureFirewall_Name
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: azureFirewall_SKU
    }
    additionalProperties: {}
    managementIpConfiguration: (useForceTunneling) ? {
      name: 'managementipconfig'
      properties: {
        publicIPAddress: {
          id: azureFirewall_Management_PIP.id
        }
        subnet: {
          id: azureFirewall_ManagementSubnet_ID
        }
      }
     } : null
    ipConfigurations: [
       {
         name: 'ipconfiguration'
         properties: {
          publicIPAddress: {
            id: azureFirewall_PIP.id
          }
           subnet: {
            id: azureFirewall_Subnet_ID
           }
         }
       }
    ]
    firewallPolicy: {
      id: azureFirewallPolicy_ID
    }
  }
  tags: tagValues
}

output azureFirewall_PrivateIPAddress string = azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
