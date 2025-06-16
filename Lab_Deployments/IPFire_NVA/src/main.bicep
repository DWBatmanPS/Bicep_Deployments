param virtualNetworkName string = 'appgw_vnet'
param virtualNetworkPrefix string = '192.168.0.0/16'
param subnet_Names array = [
  'NVAUntrust'
  'NVATrust'
  'VMSubnet'
]
param VMName string = 'WinServ2022'
param VMSize string = 'Standard_D2s_v3'
param VMAdminUsername string
@secure()
param VMAdminPassword string
param VMNICName string = 'VMNIC'
param VMSubnetName string = 'VMSubnet'
param vmscriptlocation string = 'https://raw.githubusercontent.com/Azure-Samples/windowsvm-custom-script-extension/master/vmextension/ConfigureRemotingForAnsible.ps1'
param vmscriptfilename string = 'ConfigureRemotingForAnsible.ps1'
param osDiskVhdUri string = 'https://'
param subnet1PrivateAddress string = '192.168.0.5'
param subnet2PrivateAddress string = '192.168.1.5'
param customsourceaddresscidr string

module virtualNetwork '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetworkName
  params: {
    virtualNetwork_Name: virtualNetworkName
    virtualNetwork_AddressPrefix: virtualNetworkPrefix
    subnet_Names: subnet_Names
    customsourceaddresscidr: customsourceaddresscidr
    deployudr: false
    deploy_NatGateway: false
  }
}


module IPFireNVA '../../../modules/Microsoft.Compute/IPFire/IPFire.bicep' = {
  name: 'VM1'
  params: {
    acceleratedNetworking: true
    virtualMachine_Name: 'IPFire-1'
    virtualMachine_Size: VMSize
    addPublicIPAddress: true
    privateIPAllocationMethod: 'Static'
    osDiskVhdUri: osDiskVhdUri
    vnetId: virtualNetwork.outputs.virtualNetwork_ID
    subnet1Name: subnet_Names[0]
    subnet2Name: subnet_Names[1]
    subnet1PrivateAddress: subnet1PrivateAddress
    subnet2PrivateAddress: subnet2PrivateAddress
  }
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
