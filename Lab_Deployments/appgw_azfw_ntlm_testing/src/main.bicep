param certname string = 'danwheeler-rocks-wildcard' 

param keyvault_managed_ID string = 'DWKeyVaultManagedIdentity'

param subnet_Names array = [
  'AppGatewayt'
  'PEsubnet'
  'backendSubnet'
]

param subnet_Names2 array = [
  'AzureFirewallSubnet'
]

param virtualNetworkPrefix string = '10.0.0.0/16'
param virtualNetworkPrefix2 string = '192.168.0.0/23'


param virtualNetworkName string = 'appgwvnet'
param virtualNetworkName2 string = 'azfwvnet'
param publicIPAddressName string = 'zerotrustappgw-ip'
param applicationGateWayName string = 'appgw'


param keyVaultName string = ''
@description('The name of the App Service application to create. This must be globally unique.')

param policyname string = 'azfwpolicy'
param dnsenabled bool = true
param azfwsku string = 'Premium'
param learnprivaterages string = 'Enabled'
param azfw string = 'exampleazfw'
param useForceTunneling bool = false
param homeip string = '208.107.184.241/32'
param deployudr bool = true
param azfwinternalip string = '10.0.1.4'
param scriptLocation string = 'https://raw.githubusercontent.com/danwheeler-microsoft/Bicep_Labs/main/SharedScripts/'
param scriptFileName string = 'Configure-AZFW-Ntlm.ps1'

var azfwsubnetid = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName2, 'AzureFirewallSubnet')
//var dnsServers = [
//  azfwdeploy.outputs.azureFirewall_PrivateIPAddress
//]


module virtualNetwork '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetworkName
  params: {
    virtualNetwork_Name: virtualNetworkName
    virtualNetwork_AddressPrefix: virtualNetworkPrefix
//    dnsServers: dnsServers
    subnet_Names: subnet_Names
    nvaIpAddress: azfwinternalip
    deployudr: deployudr
    customsourceaddresscidr: homeip
  }
}
 

module azfwvirtualNetwork '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetworkName2
  params: {
    virtualNetwork_Name: virtualNetworkName2
    virtualNetwork_AddressPrefix: virtualNetworkPrefix2
//    dnsServers: dnsServers
    subnet_Names: subnet_Names2
    nvaIpAddress: azfwinternalip
    deployudr: false
    customsourceaddresscidr: homeip
  }
}

module vnetpeering '../../../modules/Microsoft.Network/VirtualNetworkPeering.bicep' = {
  name: 'vnetpeering'
  params: {
    virtualNetwork_Source_Name: virtualNetworkName
    virtualNetwork_Destination_Name: virtualNetworkName2
  }
  dependsOn: [
    virtualNetwork
    azfwvirtualNetwork
  ]
}
 
module appgw '../../../modules/Microsoft.Network/ApplicationGateway_v2.bicep' = {
  name: applicationGateWayName
  params: {
    applicationGateway_Name: applicationGateWayName
    applicationGateway_SubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AGSubnet')
    publicIP_ApplicationGateway_Name: publicIPAddressName
    keyVaultName: keyVaultName
    keyvault_managed_ID: keyvault_managed_ID
    certname: certname
    isWAF: false
    usePrivateFrontend: false
    useBothPrivateAndPublicFrontend: true
    privatefrontendIP: '10.0.0.250'
    backendPoolFQDNs: []
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}

module azfwpolicy '../../../modules/Microsoft.Network/AZFWPolicy.bicep' = {
  name: policyname
  params: {
    policyname: policyname
    dnsenabled: dnsenabled
    azfwsku: azfwsku
    learnprivaterages: learnprivaterages
  }
}

module azfwdeploy '../../../modules/Microsoft.Network/AzureFirewall.bicep' = {
  name: azfw
  params: {
    azureFirewall_Name: azfw
    azureFirewallPolicy_ID: azfwpolicy.outputs.firewallpolicyid
    azureFirewall_Subnet_ID: azfwsubnetid
    azureFirewall_SKU: azfwsku
    useForceTunneling: useForceTunneling
  }
  dependsOn: [
    virtualNetwork
  ]
}

module vm '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'dwwebapp'
  params: {
    virtualMachine_Name: 'dwwebapp'
    virtualMachine_Size: 'Standard_D2s_v3'
    networkInterface_Name: 'dwwebapp-nic'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'backendSubnet')
    acceleratedNetworking: false
    addPublicIPAddress: false
    privateIPAllocationMethod: 'Static'
    privateIPAddress: '10.0.2.5'
    commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File automate-iis.ps1'
    virtualMachine_AdminPassword: 'Password1234!'
    virtualMachine_AdminUsername: 'danwheeler'
    virtualMachine_ScriptFileLocation: 'https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/'
    virtualMachine_ScriptFileName: 'automate-iis.ps1'
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}

module vm2 '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'dwwebapp2'
  params: {
    virtualMachine_Name: 'dwwebapp'
    virtualMachine_Size: 'Standard_D2s_v3'
    networkInterface_Name: 'dwwebapp-nic'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'backendSubnet')
    acceleratedNetworking: false
    addPublicIPAddress: false
    privateIPAllocationMethod: 'Static'
    privateIPAddress: '10.0.2.6'
    commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File automate-iis.ps1'
    virtualMachine_AdminPassword: 'Password1234!'
    virtualMachine_AdminUsername: 'danwheeler'
    virtualMachine_ScriptFileLocation: scriptLocation
    virtualMachine_ScriptFileName: scriptFileName
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}
