param applicationGateWayName string = 'appgw'
param publicIPAddressName string = 'appgw-vip'
param virtualNetworkName string = 'appgw_vnet'
param virtualNetworkPrefix string = '192.168.0.0/16'
param subnet_Names array = [
  'AGSubnet'
  'VMSubnet'
  'AzureBastionSubnet'
]
param keyvault_managed_ID string
param certname string
param VMName string = 'WinServ2022'
param VMSize string = 'Standard_D2s_v3'
param VMAdminUsername string
@secure()
param VMAdminPassword string
param VMNICName string = 'VMNIC'
param VMSubnetName string = 'VMSubnet'
param vmscriptlocation string = 'https://raw.githubusercontent.com/Azure-Samples/windowsvm-custom-script-extension/master/vmextension/ConfigureRemotingForAnsible.ps1'
param vmscriptfilename string = 'ConfigureRemotingForAnsible.ps1'
param keyVaultName string = 'danwheelerappgwvault'
param virtualNetwork2Name string = 'azfw_vnet'
param virtualNetwork2Prefix string = '10.0.0.0/16'
param subnet_Names2 array = [
  'AzureFirewallSubnet'
]
param policyname string = 'azfwpolicy'
param dnsenabled bool = true
param azfwsku string = 'Standard'
param learnprivaterages string = 'Enabled'
param azfw string = 'dnsazfw'
param useForceTunneling bool = false
param keyvaultmanagedidentity_name string = 'appgecertretrieval'

var azfwsubnetid = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork2Name, 'AzureFirewallSubnet')

module virtualNetwork '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetworkName
  params: {
    virtualNetwork_Name: virtualNetworkName
    virtualNetwork_AddressPrefix: virtualNetworkPrefix
    subnet_Names: subnet_Names
    deployudr: false
    deploy_NatGateway: true
    natgatewayname: 'dnscomplexnatgw'
    publicipname: 'dnscomplexnatgw-pip'
  }
}

module virtualNetwork2 '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetwork2Name
  params: {
    virtualNetwork_Name: virtualNetwork2Name
    virtualNetwork_AddressPrefix: virtualNetwork2Prefix
    subnet_Names: subnet_Names2
    deployudr: false
    deploy_NatGateway: false
  }
}

resource Keyvault_ManagedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: keyvaultmanagedidentity_name
  location: resourceGroup().location
  tags: {
  }
}

module keyvault '../../../modules/Microsoft.Keyvault/keyvault_with_managedID.bicep' = {
  name: 'keyvault'
  params: {
    keyVaultName: keyVaultName
    kvsecretofficerrole: 'Key Vault Secrets Officer'
    kvsecretuserrole: 'Key Vault Secrets User'
    managedidentity_name:keyvaultmanagedidentity_name
  }
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
    virtualNetwork2
  ]
}
module appgw '../../../modules/Microsoft.Network/Appgw_v2_incomplete.bicep' = {
  name: applicationGateWayName
  params: {
    applicationGateway_Name: applicationGateWayName
    applicationGateway_SubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AGSubnet')
    publicIP_ApplicationGateway_Name: publicIPAddressName
    keyvault_managed_ID: keyvault_managed_ID
    isWAF: false
    backendPoolFQDNs: []
    backendpoolIPAddresses: [
      '${VM.outputs.networkInterface_PrivateIPAddress}'
    ]
    nossl: true
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}

module VM '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'VM'
  params: {
    acceleratedNetworking: true
    virtualMachine_Name: VMName
    virtualMachine_AdminPassword: VMAdminPassword
    virtualMachine_AdminUsername: VMAdminUsername
    virtualMachine_Size: VMSize
    virtualMachine_ScriptFileLocation: vmscriptlocation
    virtualMachine_ScriptFileName: vmscriptfilename
    networkInterface_Name: VMNICName
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, VMSubnetName)
    commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File ${vmscriptfilename}'
    addPublicIPAddress: true
    privateIPAllocationMethod: 'Dynamic'
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}
