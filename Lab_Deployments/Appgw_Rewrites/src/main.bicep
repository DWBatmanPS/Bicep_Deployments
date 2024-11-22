param applicationGateWayName string = 'rewriteappgw'
param publicIPAddressName string = 'rewriteappgw-vip'
param virtualNetworkName string = 'rewriteappgw_vnet'
param virtualNetworkPrefix string = '192.168.0.0/16'
param subnet_Names array = [
  'AGSubnet'
  'VMSubnet'
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

param keyVaultName string = 'DanWheelerVaultStr'

module virtualNetwork '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetworkName
  params: {
    virtualNetwork_Name: virtualNetworkName
    virtualNetwork_AddressPrefix: virtualNetworkPrefix
    subnet_Names: subnet_Names
    deployudr: false
  }
}

module appgw '../../../modules/Microsoft.Network/Appgw_v2_rewrites.bicep' = {
  name: applicationGateWayName
  params: {
    applicationGateway_Name: applicationGateWayName
    applicationGateway_SubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AGSubnet')
    publicIP_ApplicationGateway_Name: publicIPAddressName
    keyVaultName: keyVaultName
    keyvault_managed_ID: keyvault_managed_ID
    certname: certname
    isWAF: false
    backendPoolFQDNs: []
    backendpoolIPAddresses: [
      '${VM.outputs.networkInterface_PrivateIPAddress}'
    ]
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
    VM
  ]
}

module VM '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'VM'
  params: {
    acceleratedNetworking: true
    location: resourceGroup().location
    virtualMachine_Name: VMName
    virtualMachine_AdminPassword: VMAdminPassword
    virtualMachine_AdminUsername: VMAdminUsername
    virtualMachine_Size: VMSize
    virtualMachine_ScriptFileLocation: ''
    virtualMachine_ScriptFileName: ''
    networkInterface_Name: VMNICName
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, VMSubnetName)
    commandToExecute: ''
    addPublicIPAddress: true
    privateIPAllocationMethod: 'Dynamic'
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}
