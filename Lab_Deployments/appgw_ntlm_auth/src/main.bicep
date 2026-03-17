param applicationGateWayName string = 'appgw'
param publicIPAddressName string = 'appgw-vip'
param virtualNetworkName string = 'appgw_vnet'
param virtualNetworkPrefix string = '192.168.0.0/16'
param privatefrontendIP string
param subnet_Names array = [
  'PrivAGSubnet'
  'VMSubnet'
  'ClientSubnet'
]
param keyvault_managed_ID string
param certname string
param VMName string = 'WinServ2022'
param VM2Name string = 'WinServ2022-2'
param VMSize string = 'Standard_D2s_v3'
param VMAdminUsername string
@secure()
param VMAdminPassword string
param VM1NICName string = 'VM1NIC'
param VM2NICName string = 'VM2NIC'
param VM3NICName string = 'CLIENTVMNIC'
param VMSubnetName string = 'VMSubnet'
param ClientSubnetName string = 'ClientSubnet'
param vmscriptlocation string = 'https://raw.githubusercontent.com/Azure-Samples/windowsvm-custom-script-extension/master/vmextension/ConfigureRemotingForAnsible.ps1'
param vmscriptfilename string = 'ConfigureRemotingForAnsible.ps1'
param keyVaultName string = 'DanWheelerVaultStr'
param customsourceaddresscidr string = '1.1.1.1/32'

module virtualNetwork '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetworkName
  params: {
    virtualNetwork_Name: virtualNetworkName
    virtualNetwork_AddressPrefix: virtualNetworkPrefix
    subnet_Names: subnet_Names
    customsourceaddresscidr: customsourceaddresscidr
    deploy_NatGateway: true
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
    usePrivateFrontend: true
    privatefrontendIP: privatefrontendIP
    isE2ESSL: true
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

module VM1 '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'VM1'
  params: {
    acceleratedNetworking: true
    virtualMachine_Name: VMName
    virtualMachine_AdminPassword: VMAdminPassword
    virtualMachine_AdminUsername: VMAdminUsername
    virtualMachine_Size: VMSize
    virtualMachine_ScriptFileLocation: vmscriptlocation
    virtualMachine_ScriptFileName: vmscriptfilename
    networkInterface_Name: VM1NICName
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

module VM2 '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'VM2'
  params: {
    acceleratedNetworking: true
    virtualMachine_Name: VM2Name
    virtualMachine_AdminPassword: VMAdminPassword
    virtualMachine_AdminUsername: VMAdminUsername
    virtualMachine_Size: VMSize
    virtualMachine_ScriptFileLocation: vmscriptlocation
    virtualMachine_ScriptFileName: vmscriptfilename
    networkInterface_Name: VM2NICName
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

module ClientVM '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'ClientVM'
  params: {
    acceleratedNetworking: true
    virtualMachine_Name: 'ClientVM'
    virtualMachine_AdminPassword: VMAdminPassword
    virtualMachine_AdminUsername: VMAdminUsername
    virtualMachine_Size: VMSize
    virtualMachine_ScriptFileLocation: vmscriptlocation
    virtualMachine_ScriptFileName: vmscriptfilename
    networkInterface_Name: VM3NICName
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, ClientSubnetName)
    commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File ${vmscriptfilename}'
    addPublicIPAddress: true
    privateIPAllocationMethod: 'Dynamic'
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}
