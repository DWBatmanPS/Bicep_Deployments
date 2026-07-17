// Private-frontend Application Gateway (Standard_v2) doing SSL Offload to a Windows/IIS backend.
// Topology: 1 VNet, 4 subnets (AppGW, Backend VM, Client VM, AzureBastionSubnet), Bastion for access.

// ---------- Network ----------
param virtualNetworkName string = 'appgw-priv-ssloffload-vnet'
param virtualNetworkPrefix string = '10.0.0.0/16'

// The VirtualNetwork module assigns each subnet a /24 based on its index in this array:
//   index 0 -> 10.0.0.0/24 (ApplicationGatewaySubnet)
//   index 1 -> 10.0.1.0/24 (BackendSubnet)
//   index 2 -> 10.0.2.0/24 (ClientSubnet)
//   index 3 -> 10.0.3.0/24 (AzureBastionSubnet, >= /26)
param subnet_Names array = [
  'ApplicationGatewaySubnet'
  'BackendSubnet'
  'ClientSubnet'
  'AzureBastionSubnet'
]

param appGatewaySubnetName string = 'ApplicationGatewaySubnet'
param backendSubnetName string = 'BackendSubnet'
param clientSubnetName string = 'ClientSubnet'

// ---------- Application Gateway ----------
param applicationGateWayName string = 'appgw-priv-ssloffload'
param publicIPAddressName string = 'appgw-priv-ssloffload-pip'
param privatefrontendIP string = '10.0.0.250'
param certname string = 'danwheeler-cert'
param keyVaultName string = 'danwheeler-awoxs5-kv'
param keyvault_managed_ID string = 'DWKeyVaultManagedIdentity'

// ---------- Virtual Machines ----------
param backendVMName string = 'iisbackend'
param clientVMName string = 'clientvm'
param VMSize string = 'Standard_D2s_v3'

@description('Admin username for both the backend and client VMs. Supplied at deploy time.')
param VMAdminUsername string

@secure()
@description('Admin password for both the backend and client VMs. Supplied at deploy time.')
param VMAdminPassword string

// ---------- Bastion ----------
param bastionName string = 'appgw-priv-ssloffload-bastion'

module virtualNetwork '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetworkName
  params: {
    virtualNetwork_Name: virtualNetworkName
    virtualNetwork_AddressPrefix: virtualNetworkPrefix
    subnet_Names: subnet_Names
    deployudr: false
  }
}

module backendVM '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: backendVMName
  params: {
    virtualMachine_Name: backendVMName
    virtualMachine_Size: VMSize
    virtualMachine_AdminUsername: VMAdminUsername
    virtualMachine_AdminPassword: VMAdminPassword
    acceleratedNetworking: false
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, backendSubnetName)
    addPublicIPAddress: false
    virtualMachine_ScriptFileLocation: 'https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/'
    virtualMachine_ScriptFileName: 'automate-iis.ps1'
    commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File automate-iis.ps1'
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}

module clientVM '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: clientVMName
  params: {
    virtualMachine_Name: clientVMName
    virtualMachine_Size: VMSize
    virtualMachine_AdminUsername: VMAdminUsername
    virtualMachine_AdminPassword: VMAdminPassword
    acceleratedNetworking: false
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, clientSubnetName)
    addPublicIPAddress: false
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}

module appgw '../../../modules/Microsoft.Network/ApplicationGateway_v2.bicep' = {
  name: applicationGateWayName
  params: {
    applicationGateway_Name: applicationGateWayName
    applicationGateway_SubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, appGatewaySubnetName)
    publicIP_ApplicationGateway_Name: publicIPAddressName
    keyVaultName: keyVaultName
    keyvault_managed_ID: keyvault_managed_ID
    certname: certname
    isWAF: false
    isE2ESSL: false
    nossl: false
    usePrivateFrontend: true
    useBothPrivateAndPublicFrontend: false
    privatefrontendIP: privatefrontendIP
    backendpoolIPAddresses: [
      backendVM.outputs.networkInterface_PrivateIPAddress
    ]
    backendPoolFQDNs: []
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}

module bastion '../../../modules/Microsoft.Network/Bastion.bicep' = {
  name: bastionName
  params: {
    location: resourceGroup().location
    bastion_name: bastionName
    bastion_SubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AzureBastionSubnet')
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}
