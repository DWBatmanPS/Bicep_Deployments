param RGName1 string = 'ATM-EUS'

param DeploymentLocation1 string = 'centralus'

param ATM_Name string = 'DanWMultiValueATM'
param atmsubdomain string = 'DanWMultiValueATM'
param RoutingMethod string = 'MultiValue'
param probeProtocol string = 'HTTP'
param customPort int = 80
param VMName string = 'DanWMultiValueVM'
param VMAdminUsername string = 'DanWMultiValueAdmin'
@secure()
param VMAdminPassword string = ''
param VMSize string = 'Standard_D2s_v3'
param VMNICName string = 'VMNIC'
param VMSubnetName string = 'VMSubnet'
param virtualNetworkName string = 'DanWMultiValueVNet'
param virtualNetworkPrefix string = '10.0.0.0/16'
param subnet_Names array = [
  'VMSubnet'
]
param vmscriptlocation string = 'https://raw.githubusercontent.com/Azure-Samples/windowsvm-custom-script-extension/master/vmextension/ConfigureRemotingForAnsible.ps1'
param vmscriptfilename string = 'ConfigureRemotingForAnsible.ps1'

targetScope = 'subscription'

resource rg1_deployment 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: RGName1
  location: DeploymentLocation1
}

module atm '../../../modules/Microsoft.Network/ATM_Deployment_noEndpoints.bicep' = {
  name: 'ATM_Deployment'
  scope: rg1_deployment
  params: {
    ATM_Name:ATM_Name
    atmsubdomain: atmsubdomain
    RoutingMethod: RoutingMethod
    probeProtocol: probeProtocol
    customPort: customPort
  }
}


module VM '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'VM'
  scope: rg1_deployment
  params: {
    acceleratedNetworking: false
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

module virtualNetwork '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetworkName
  scope: rg1_deployment
  params: {
    virtualNetwork_Name: virtualNetworkName
    virtualNetwork_AddressPrefix: virtualNetworkPrefix
    subnet_Names: subnet_Names
    deployudr: false
  }
}
