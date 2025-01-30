param virtualNetworkName string = 'appgw_vnet'
param virtualNetworkPrefix string = '192.168.0.0/16'
param subnet_Names array = [
  'VMSubnet'
  'AzureBastionSubnet'
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
param ILBDeployment string = 'InternalLoadBalancer'
param publicipname string = 'NAT_Gateway_VIP'
param natgatewayname string = 'NAT_Gateway'

module virtualNetwork '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetworkName
  params: {
    virtualNetwork_Name: virtualNetworkName
    virtualNetwork_AddressPrefix: virtualNetworkPrefix
    subnet_Names: subnet_Names
    deployudr: false
    deploy_NatGateway: true
    publicipname: publicipname
    natgatewayname: natgatewayname
  }
}


module VM1 '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'VM1'
  params: {
    acceleratedNetworking: true
    virtualMachine_Name: '${VMName}-1'
    virtualMachine_AdminPassword: VMAdminPassword
    virtualMachine_AdminUsername: VMAdminUsername
    virtualMachine_Size: VMSize
    virtualMachine_ScriptFileLocation: vmscriptlocation
    virtualMachine_ScriptFileName: vmscriptfilename
    networkInterface_Name:'${VMNICName}-1'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, VMSubnetName)
    commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File ${vmscriptfilename}'
    addPublicIPAddress: true
    privateIPAllocationMethod: 'Dynamic'
    addtoloadbalancer: true
    loadbalancername: ILBDeployment
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
    ILB
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
    addPublicIPAddress: true
    privateIPAllocationMethod: 'Dynamic'
    addtoloadbalancer: true
    loadbalancername: ILBDeployment
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
    ILB
  ]
}

module ILB '../../../modules/Microsoft.Network/InternalLoadBalancer.bicep' = {
  name: ILBDeployment
  params: {
    internalLoadBalancer_Name: ILBDeployment
    internalLoadBalancer_SubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, VMSubnetName)
    tcpPort: 80
    enableTcpReset: true
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}
