param vnet1_Name string = 'vnet1'
param vnet2_Name string = 'vnet2'
param vhub1_Name string = 'vhub1'
param vhub2_Name string = 'vhub2'
param vnet1_Location string = 'eastus'
param vnet2_Location string = 'centralus'
param vhub1_Location string = 'eastus'
param vhub2_Location string = 'centralus'
param vwan_Name string = 'vwan'
param vnet1_Cidr string = '192.168.0.0/20'
param vnet2_Cidr string = '192.168.16.0/20'
param vhub1_Cidr string = '10.0.0.0/24'
param vhub2_Cidr string = '10.0.1.0/24'
param vnet1_subnets array = [
    'subnet1'
    'subnet2'
    'subnet3'
]
param vnet2_subnets array = [
    'subnet1'
    'subnet2'
    'subnet3'
]
param connectingIP string = '1.1.1.1'
param vmname string = 'vm'
param vmsize string = 'Standard_D2s_v3'
param vmadmin string = 'adminuser'
@secure()
param vmpassword string


param tags object = {}

module vwan '../../../modules/Microsoft.Network/VirtualWAN.bicep' = {
  name: vwan_Name
  params: {
    location: resourceGroup().location
    virtualWAN_Name: 'vwan'
    tagValues: tags
  }
}

module vhub1 '../../../modules/Microsoft.Network/VirtualHub.bicep' = {
  name: vhub1_Name
  params: {
    location: vhub1_Location
    virtualWAN_ID: vwan.outputs.virtualWAN_ID
    virtualHub_Name: vhub1_Name
    virtualHub_AddressPrefix: vhub1_Cidr
    usingAzureFirewall: false
    usingVPN: false
    tagValues: tags
  }
}

module vhub2 '../../../modules/Microsoft.Network/VirtualHub.bicep' = {
  name: vhub2_Name
  params: {
    location: vhub2_Location
    virtualWAN_ID: vwan.outputs.virtualWAN_ID
    virtualHub_Name: vhub2_Name
    virtualHub_AddressPrefix: vhub2_Cidr
    usingAzureFirewall: false
    usingVPN: false
    tagValues: tags
  }
}

module vnet1 '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: vnet1_Name
  params: {
    customlocation: vnet1_Location
    virtualNetwork_Name: vnet1_Name
    virtualNetwork_AddressPrefix: vnet1_Cidr
    subnet_Names: vnet1_subnets
    customsourceaddresscidr: connectingIP
    UsecustomLocation: true
    tagValues: tags
  }
}

module vnet2 '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: vnet2_Name
  params: {
    customlocation: vnet2_Location
    virtualNetwork_Name: vnet2_Name
    virtualNetwork_AddressPrefix: vnet2_Cidr
    subnet_Names: vnet2_subnets
    customsourceaddresscidr: connectingIP
    UsecustomLocation: true
    tagValues: tags
  }
}

module vm1 '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'vm1'
  params: {
    acceleratedNetworking: false
    networkInterface_Name: '${vmname}-${vnet1_Location}-1-nic'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet1_Name ,vnet1_subnets[0])
    addPublicIPAddress: true
    privateIPAllocationMethod: 'Dynamic'
    virtualMachine_Name: '${vmname}-${vnet1_Location}-1'
    virtualMachine_Size: vmsize
    virtualMachine_AdminUsername: vmadmin
    virtualMachine_AdminPassword: vmpassword
    tagValues: tags
  }
  dependsOn: [
    vhub1connection
  ]
}

module vm2 '../../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'vm2'
  params: {
    acceleratedNetworking: false
    networkInterface_Name: '${vmname}-${vnet2_Location}-1-nic'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet2_Name ,vnet2_subnets[0])
    addPublicIPAddress: true
    privateIPAllocationMethod: 'Dynamic'
    virtualMachine_Name: '${vmname}-${vnet2_Location}-1'
    virtualMachine_Size: vmsize
    virtualMachine_AdminUsername: vmadmin
    virtualMachine_AdminPassword: vmpassword
    tagValues: tags
  }
  dependsOn: [
    vhub2connection
  ]
}

module vhub1connection '../../../modules/Microsoft.Network/virtualhubnetworkconnection.bicep' = {
  name: '${vhub1_Name}to${vnet1_Name}'
  params: {
    virtualHub_Name: vhub1.outputs.virtualHub_Name
    virtualNetwork_Name: vnet1.outputs.virtualNetwork_Name
    virtualNetwork_ID: vnet1.outputs.virtualNetwork_ID
    virtualHub_RouteTable_Default_ID: vhub1.outputs.virtualHub_RouteTable_Default_ID
  }
}

module vhub2connection '../../../modules/Microsoft.Network/virtualhubnetworkconnection.bicep' = {
  name: '${vhub2_Name}to${vnet2_Name}'
  params: {
    virtualHub_Name: vhub2.outputs.virtualHub_Name
    virtualNetwork_Name: vnet2.outputs.virtualNetwork_Name
    virtualNetwork_ID: vnet2.outputs.virtualNetwork_ID
    virtualHub_RouteTable_Default_ID: vhub2.outputs.virtualHub_RouteTable_Default_ID
  }
}
