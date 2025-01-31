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
    pathmap: true
    path: '/path'
    backendPoolFQDNs: []
    backendpoolIPAddresses: [
      '${VM.outputs.networkInterface_PrivateIPAddress}'
    ]
    backendpoolpathIPAddresses: [
      '${VM2.outputs.networkInterface_PrivateIPAddress}'
    ]
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
    addPublicIPAddress: false
    privateIPAllocationMethod: 'Dynamic'
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}

module VM2 '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'VM2'
  params: {
    acceleratedNetworking: true
    virtualMachine_Name: '${VMName}-2'
    virtualMachine_AdminPassword: VMAdminPassword
    virtualMachine_AdminUsername: VMAdminUsername
    virtualMachine_Size: VMSize
    virtualMachine_ScriptFileLocation: vmscriptlocation
    virtualMachine_ScriptFileName: vmscriptfilename
    networkInterface_Name: '${VMNICName}-2'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, VMSubnetName)
    commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File ${vmscriptfilename}'
    addPublicIPAddress: false
    privateIPAllocationMethod: 'Dynamic'
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}
