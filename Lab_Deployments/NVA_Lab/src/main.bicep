param vnet_name string = 'NVAVnet'
param dnsServers array = [
  '10.0.1.5'
  '168.63.129.16'
  '10.0.1.6'
]
param virtualNetwork_AddressPrefix string = '10.0.0.0/16'
param subnet_Names array = [
  'WebServerVM'
  'NVATrust'
  'NVAUntrust'
  'NVAMgmt'
]
param nvaip string = '10.0.1.4'
param customcidr string
param NVA1trustIP string = '10.0.1.5'
param NVA1untrustIP string = '10.0.2.5'
param NVA2trustIP string = '10.0.1.6'
param NVA2untrustIP string = '10.0.2.6'
//param OpnsenseImage string = 'OPNsense-21.7-OpenSSL-dvd-amd64'
param NVA_name string = 'NVA'
param VMSize string = 'Standard_D2s_v3'
param webserveradmin string = 'webadmin'
@secure()
param webserverpassword string
param script_location string
param script_name string = 'webserverconfig.sh'

module Vnet '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: 'Vnet'
  params: {
    virtualNetwork_Name: vnet_name
    dnsServers: dnsServers
    virtualNetwork_AddressPrefix: virtualNetwork_AddressPrefix
    subnet_Names: subnet_Names
    nvaIpAddress: nvaip
    deployudr: true
    customsourceaddresscidr: customcidr
  }
}

module NVA1TrustNIC '../../../modules/Microsoft.Network/NetworkInterface.bicep' = {
  name: '${NVA_name}_1_nic_trust'
  params: {
    acceleratedNetworking: false
    networkInterface_Name: '${NVA_name}_1_nic_trust'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name, subnet_Names[1])
    privateIPAddress: NVA1trustIP
    privateIPAllocationMethod: 'Static'
    addPublicIPAddress: false
    tagValues: {}
  }
  dependsOn: [
    Vnet
  ]
}

module NVA1UntrustNIC '../../../modules/Microsoft.Network/NetworkInterface.bicep' = {
  name: '${NVA_name}_1_nic_untrust'
  params: {
    acceleratedNetworking: false
    networkInterface_Name: '${NVA_name}_1_nic_untrust'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name, subnet_Names[2])
    privateIPAddress: NVA1untrustIP
    privateIPAllocationMethod: 'Static'
    addPublicIPAddress: true
    tagValues: {}
  }
  dependsOn: [
    Vnet
  ]
}

module NVA1MgmtNIC '../../../modules/Microsoft.Network/NetworkInterface.bicep' = {
  name: '${NVA_name}_1_nic_mgmt'
  params: {
    acceleratedNetworking: false
    networkInterface_Name: '${NVA_name}_1_nic_mgmt'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name, subnet_Names[3])
    privateIPAllocationMethod: 'Dynamic'
    addPublicIPAddress: false
    tagValues: {}
  }
  dependsOn: [
    Vnet
  ]
}

module NVA1 '../../../modules/Microsoft.Compute/OPNSense/OpnSenseNVA.bicep' = {
  name: '${NVA_name}1'
  params: {
    NVAName: '${NVA_name}1'
    VMSize: VMSize
//     imageReference_Id: OpnsenseImage
    untrustnic_objectid: NVA1UntrustNIC.outputs.networkInterface_ID
    trustnic_objectid: NVA1TrustNIC.outputs.networkInterface_ID
    virtualMachine_AdminUsername: 'azureadmin'
    virtualMachine_AdminPassword: 'Password1234!'
  }
  dependsOn: [
    Vnet
  ]
}

module NVA2TrustNIC '../../../modules/Microsoft.Network/NetworkInterface.bicep' = {
  name: '${NVA_name}_2_nic_trust'
  params: {
    acceleratedNetworking: false
    networkInterface_Name: '${NVA_name}_2_nic_trust'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name, subnet_Names[1])
    privateIPAddress: NVA2trustIP
    privateIPAllocationMethod: 'Static'
    addPublicIPAddress: false
    tagValues: {}
  }
  dependsOn: [
    Vnet
  ]
}

module NVA2UntrustNIC '../../../modules/Microsoft.Network/NetworkInterface.bicep' = {
  name: '${NVA_name}_2_nic_untrust'
  params: {
    acceleratedNetworking: false
    networkInterface_Name: '${NVA_name}_2_nic_untrust'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name, subnet_Names[2])
    privateIPAddress: NVA2untrustIP
    privateIPAllocationMethod: 'Static'
    addPublicIPAddress: false
    tagValues: {}
  }
  dependsOn: [
    Vnet
  ]
}

module NVA2MgmtNIC '../../../modules/Microsoft.Network/NetworkInterface.bicep' = {
  name: '${NVA_name}_2_nic_mgmt'
  params: {
    acceleratedNetworking: false
    networkInterface_Name: '${NVA_name}_2_nic_mgmt'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name, subnet_Names[3])
    privateIPAllocationMethod: 'Dynamic'
    addPublicIPAddress: false
    tagValues: {}
  }
  dependsOn: [
    Vnet
  ]
}

module NVA2 '../../../modules/Microsoft.Compute/OPNSense/OpnSenseNVA.bicep' = {
  name: '${NVA_name}2'
  params: {
    NVAName: '${NVA_name}2'
    VMSize: VMSize
   //mageReference_Id: OpnsenseImage
    untrustnic_objectid: NVA2UntrustNIC.outputs.networkInterface_ID
    trustnic_objectid: NVA2TrustNIC.outputs.networkInterface_ID
    virtualMachine_AdminUsername: 'azureadmin'
    virtualMachine_AdminPassword: 'Password1234!'
  }
  dependsOn: [
    Vnet
  ]
}

module WebServer '../../../modules/Microsoft.Compute/Ubuntu20/VirtualMachine.bicep' = {
  name: 'WebServer'
  params: {
    virtualMachine_Name: 'UbuntuWebServer'
    virtualMachine_Size: 'Standard_D2s_v4'
    networkInterface_Name: 'WebServer_NIC'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name, subnet_Names[0])
    virtualMachine_AdminUsername: webserveradmin
    virtualMachine_AdminPassword: webserverpassword
    acceleratedNetworking: false
    privateIPAddress: 'Dynamic'
    virtualMachine_ScriptFileLocation: script_location
    virtualMachine_ScriptFileName: script_name 
    commandToExecute: 'bash ${script_name}'
    tagValues: {}
  }
  dependsOn: [
    Vnet
  ]
}
