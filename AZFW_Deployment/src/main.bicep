param policyname string = 'azfwpolicy'
param dnsenabled bool = true
param azfwsku string = 'Standard'
param learnprivaterages string = 'Enabled'
param azfw string = 'exampleazfw'
param VnetName string = 'default'
param VnetPrefix string = '10.0.0.0/16'
param useForceTunneling bool = false
param dnsServers array = []
param subnet_Names array = [
  'AzureFirewallSubnet'
]

var location = resourceGroup().location
var azfwsubnetid = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', VnetName, 'subnets', 'AzureFirewallSubnet')

module vnet '../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: VnetName
  params: {
    location: location
    virtualNetwork_Name: VnetName
    virtualNetwork_AddressPrefix: VnetPrefix
    dnsServers: dnsServers
    subnet_Names: subnet_Names
  }
}

module azfwpolicy '../..//modules/Microsoft.Network/AZFWPolicy.bicep' = {
  name: policyname
  params: {
    policyname: policyname
    location: location
    dnsenabled: dnsenabled
    azfwsku: azfwsku
    learnprivaterages: learnprivaterages
  }
}

module azfwdeploy '../../modules/Microsoft.Network/AzureFirewall.bicep' = {
  name: azfw
  params: {
    azureFirewall_Name: azfw
    location: location
    azureFirewallPolicy_ID: azfwpolicy.outputs.firewallpolicyid
    azureFirewall_Subnet_ID: azfwsubnetid
    azureFirewall_SKU: azfwsku
    useForceTunneling: useForceTunneling
  }
}
