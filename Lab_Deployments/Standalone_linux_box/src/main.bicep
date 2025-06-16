param virtualNetworkName string = 'VirtualNetwork'
param virtualNetworkPrefix string = '10.0.0.0/8'
param subnet_Names array = [
  'Subnet1'
  'Subnet2'
  'Subnet3'
]
param serveradmin string = 'webadmin'
@secure()
param serverpassword string
@secure()
param SSHKey string = ''
param script_location string = 'https://raw.githubusercontent.com/user/repo/main/scripts/'
param script_name string = 'WebServerSetup.sh'




module virtualNetwork '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: virtualNetworkName
  params: {
    virtualNetwork_Name: virtualNetworkName
    virtualNetwork_AddressPrefix: virtualNetworkPrefix
    subnet_Names: subnet_Names
    deployudr: false
    deploy_NatGateway: false
  }
}


module WebServer '../../../modules/Microsoft.Compute/Ubuntu20/VirtualMachine.bicep' = {
  name: 'WebServer'
  params: {
    virtualMachine_Name: 'UbuntuWebServer'
    virtualMachine_Size: 'Standard_D2s_v4'
    networkInterface_Name: 'Server_NIC'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnet_Names[0])
    virtualMachine_AdminUsername: serveradmin
    virtualMachine_AdminPassword: serverpassword
    SSHKey: SSHKey
    acceleratedNetworking: false
    privateIPAddress: 'Dynamic'
    addPublicIPAddress: true
    virtualMachine_ScriptFileLocation: script_location
    virtualMachine_ScriptFileName: script_name 
    commandToExecute: ''
    tagValues: {}
  }
  dependsOn: [
    virtualNetwork
  ]
}
