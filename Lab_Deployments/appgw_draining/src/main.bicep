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
param VMName string = 'UbuntuVM'
param VMSize string = 'Standard_D2s_v3'
param VMAdminUsername string
@secure()
param VMAdminPassword string
@secure()
param SSHKey string = ''
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
    backendPoolFQDNs: []
    backendpoolIPAddresses: [
      '${VM1.outputs.networkInterface_PrivateIPAddress}'
      '${VM2.outputs.networkInterface_PrivateIPAddress}'
    ]
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}

module VM1 '../../../modules/Microsoft.Compute/Ubuntu20/VirtualMachine.bicep' = {
  name: 'VM1'
  params: {
    acceleratedNetworking: true
    virtualMachine_Name: '${VMName}-1'
    virtualMachine_AdminPassword: VMAdminPassword
    virtualMachine_AdminUsername: VMAdminUsername
    virtualMachine_Size: VMSize
    networkInterface_Name: '${VMNICName}-1'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, VMSubnetName)
    addPublicIPAddress: true
    privateIPAllocationMethod: 'Dynamic'
    SSHKey: SSHKey
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}

module VM2 '../../../modules/Microsoft.Compute/Ubuntu20/VirtualMachine.bicep' = {
  name: 'VM2'
  params: {
    acceleratedNetworking: true
    virtualMachine_Name: '${VMName}-2'
    virtualMachine_AdminPassword: VMAdminPassword
    virtualMachine_AdminUsername: VMAdminUsername
    virtualMachine_Size: VMSize
    networkInterface_Name: '${VMNICName}-2'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, VMSubnetName)
    addPublicIPAddress: true
    privateIPAllocationMethod: 'Dynamic'
    SSHKey: SSHKey
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}

module bastion '../../../modules/Microsoft.Network/Bastion.bicep' = {
  name: 'bastion'
  params: {
    bastion_name: 'bastion'
    location: resourceGroup().location
    bastion_SubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AzureBastionSubnet')
  }
  dependsOn: [
    virtualNetwork
  ]
}
