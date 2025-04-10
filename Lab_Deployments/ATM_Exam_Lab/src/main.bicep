param RGName1 string = 'EastUS'
param DeploymentLocation1 string = 'eastus'
param RGName2 string = 'WestEurope'
param RGName3 string = 'CentralUS'
param DeploymentLocation2 string = 'West Europe'
param DeploymentLocation3 string = 'Central US'

param ATM1_Name string = 'bicep-atm-profile'
param atm1RoutingMethod string = 'Performance'
param ATM2_Name string = 'bicep-atm-profile'
param ATM2_ChildName string = 'bicep-atm-child-profile'
param atm2RoutingMethod string = 'Geographic'
param probeProtocol string = 'TCP'
param virtualMachine1_Name string = 'bicep-vm-profile'
param virtualMachine2_Name string = 'bicep-vm-profile'
param virtualMachine3_Name string = 'bicep-vm-profile'
param virtualMachine_Size string = 'Standard_DS2_v2'
param virtualMachine_AdminUsername string
@secure()
param virtualMachine_AdminPassword string
param virtualMachine_ScriptFileLocation string = 'https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/101-vm-simple-windows/'
param virtualMachine_ScriptFileName string = 'azuredeploy.ps1'
param commandToExecute string = 'powershell.exe -ExecutionPolicy Unrestricted -File azuredeploy.ps1'
param networkInterface_Name string = 'bicep-vm-profile-nic'
param acceleratedNetworking bool = true
param privateIPAllocationMethod string = 'Dynamic'
param vnet1name string = 'bicep-vnet-profile'
param vnet1AddressPrefix string = '10.0.0.0/16'
param vnet1subnets array = [
  'subnet'
]
param vnet2name string = 'bicep-vnet-profile'
param vnet2AddressPrefix string = '10.0.0.0/16'
param vnet2subnets array = [
  'subnet'
]
param testingengineername string = 'John_Doe'

var vm1ip = VM1RG1.outputs.publicIPAddress
var vm2ip = VM1RG2.outputs.publicIPAddress
var endpoint = concat([vm1ip], [vm2ip])
var tags = {
  Engineer: testingengineername
}

targetScope = 'subscription'

resource rg1_deployment 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: RGName1
  location: DeploymentLocation1
  tags: tags
}

resource rg2_deployment'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: RGName2
  location: DeploymentLocation2
  tags: tags
}

resource rg3_deployment 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: RGName3
  location: DeploymentLocation3
  tags: tags
}

module atm1 'atm.bicep' = {
  name: 'ATM1_Deployment'
  scope: rg3_deployment
  params: {
    ATM_Name:ATM1_Name
    RoutingMethod: atm1RoutingMethod
    probeProtocol: probeProtocol
    endpoint: endpoint
    tags: tags
  }
}

module atm2 'atmnested.bicep' = {
  name: 'ATM2_Deployment'
  scope: rg3_deployment
  params: {
    ATM_Name:ATM2_Name
    ATMchild_Name: ATM2_ChildName
    RoutingMethod: atm2RoutingMethod
    probeProtocol: probeProtocol
    endpoint1: VM1RG1.outputs.publicIPAddress
    endpoint2: VM1RG2.outputs.publicIPAddress
    endpoint3: VM2RG2.outputs.publicIPAddress
    tags: tags
  }
}


module VM1RG1 'VM.bicep' = {
  name: 'VM1_Deployment'
  scope: rg1_deployment
  params: {
    virtualMachine_Name: virtualMachine1_Name
    virtualMachine_Size: virtualMachine_Size
    virtualMachine_AdminUsername: virtualMachine_AdminUsername
    virtualMachine_AdminPassword: virtualMachine_AdminPassword
    virtualMachine_ScriptFileLocation: virtualMachine_ScriptFileLocation
    virtualMachine_ScriptFileName: virtualMachine_ScriptFileName
    commandToExecute: commandToExecute
    networkInterface_Name: networkInterface_Name
    location: rg1_deployment.location
    acceleratedNetworking: acceleratedNetworking
    privateIPAllocationMethod: privateIPAllocationMethod
    subnet_ID: vnet1.outputs.subnets[0].id
    tags: tags
  }
}

module vnet1 'vnet.bicep' = {
  name: 'VNet1_Deployment'
  scope: rg1_deployment
  params: {
    virtualNetwork_Name: vnet1name
    virtualNetwork_AddressPrefix: vnet1AddressPrefix
    subnet_Names: vnet1subnets
    tags: tags
  }
  }

  module vnet2 'vnet.bicep' = {
    name: 'VNet2_Deployment'
    scope: rg2_deployment
    params: {
      virtualNetwork_Name: vnet2name
      virtualNetwork_AddressPrefix: vnet2AddressPrefix
      subnet_Names: vnet2subnets
      breakNSG: true
      tags: tags
    }
    }

    
module VM1RG2 'VM.bicep' = {
  name: 'VM2_Deployment'
  scope: rg2_deployment
  params: {
    virtualMachine_Name: virtualMachine2_Name
    virtualMachine_Size: virtualMachine_Size
    virtualMachine_AdminUsername: virtualMachine_AdminUsername
    virtualMachine_AdminPassword: virtualMachine_AdminPassword
    virtualMachine_ScriptFileLocation: virtualMachine_ScriptFileLocation
    virtualMachine_ScriptFileName: virtualMachine_ScriptFileName
    commandToExecute: commandToExecute
    networkInterface_Name: networkInterface_Name
    location: rg2_deployment.location
    acceleratedNetworking: acceleratedNetworking
    privateIPAllocationMethod: privateIPAllocationMethod
    subnet_ID: vnet2.outputs.subnets[0].id
    tags: tags
  }
}

module VM2RG2 'VM.bicep' = {
  name: 'VM3_Deployment'
  scope: rg2_deployment
  params: {
    virtualMachine_Name: virtualMachine3_Name
    virtualMachine_Size: virtualMachine_Size
    virtualMachine_AdminUsername: virtualMachine_AdminUsername
    virtualMachine_AdminPassword: virtualMachine_AdminPassword
    virtualMachine_ScriptFileLocation: virtualMachine_ScriptFileLocation
    virtualMachine_ScriptFileName: virtualMachine_ScriptFileName
    commandToExecute: commandToExecute
    networkInterface_Name: '${networkInterface_Name}-2'
    location: rg2_deployment.location
    acceleratedNetworking: acceleratedNetworking
    privateIPAllocationMethod: privateIPAllocationMethod
    subnet_ID: vnet2.outputs.subnets[0].id
    tags: tags
  }
}
