param vnet1_name string = 'NVAVnet'
param vnet2_name string = 'SpokeVnet'
param virtualNetwork1_AddressPrefix string = '10.0.0.0/16'
param virtualNetwork2_AddressPrefix string = '10.1.0.0/16'
param vnet1subnet_Names array = [
  'NVATrust'
  'NVAUntrust'
  'NVAMgmt'
  'RouteServerSubnet'
  'GatewaySubnet'
]
param vnet2subnet_Names array = [
  'PESubnet'
  'VMsubnet'
]
param nvaip string = '10.0.1.4'
param customcidr string
param NVA1trustIP string = '10.0.0.5'
param NVA1untrustIP string = '10.0.1.5'
param NVA_name string = 'NVA'
param VMSize string = 'Standard_D2s_v3'
param webserveradmin string = 'webadmin'
@secure()
param webserverpassword string
param script_location string
param script_name string = 'webserverconfig.sh'
param OnPremName string = 'OnPrem'
param OnPremPublicIP string 
param OnPremBGPIP string
param OnPremASN int = 65000
@secure()
param OnPremSharedKey string
@secure()
param SSHKey string
param OPNScriptURI string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-vm-opnsense-nva/scripts/'
param ScriptName string = 'opnsense.sh'
param OPNVersion string = '25.1'
param WALinuxVersion string = '2.12.0.4'


module NVAVnet '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: 'NVAVnet'
  params: {
    virtualNetwork_Name: vnet1_name

    virtualNetwork_AddressPrefix: virtualNetwork1_AddressPrefix
    subnet_Names: vnet1subnet_Names
    deployudr: false
    customsourceaddresscidr: customcidr
  }
}

module SpokeVnet '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: 'SpokeVnet'
  params: {
    virtualNetwork_Name: vnet2_name
    virtualNetwork_AddressPrefix: virtualNetwork2_AddressPrefix
    subnet_Names: vnet2subnet_Names
    deployudr: false
    customsourceaddresscidr: customcidr
  }
}

module vnetPeering '../../../modules/Microsoft.Network/VirtualNetworkPeering.bicep' = {
  name: 'VnetPeering'
  params: {
    virtualNetwork_Source_Name: vnet1_name
    virtualNetwork_Destination_Name: vnet2_name
  }
  dependsOn: [
    NVAVnet
    SpokeVnet
  ]
}

module RouteServer '../../../modules/Microsoft.Network/routeserver.bicep' = {
  name: 'RouteServer'
  params: {
    RouteServerName: 'RouteServer'
    location: resourceGroup().location
    virtualNetwork_Name: vnet1_name
    NVA_ASN: 65002
    NVAip: nvaip
  }
  dependsOn: [
    NVAVnet
  ]
}

module NVA1TrustNIC '../../../modules/Microsoft.Network/NetworkInterface.bicep' = {
  name: '${NVA_name}_1_nic_trust'
  params: {
    acceleratedNetworking: false
    networkInterface_Name: '${NVA_name}_1_nic_trust'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet1_name, vnet1subnet_Names[0])
    privateIPAddress: NVA1trustIP
    privateIPAllocationMethod: 'Static'
    addPublicIPAddress: false
    tagValues: {}
  }
  dependsOn: [
    NVAVnet
  ]
}

module NVA1UntrustNIC '../../../modules/Microsoft.Network/NetworkInterface.bicep' = {
  name: '${NVA_name}_1_nic_untrust'
  params: {
    acceleratedNetworking: false
    networkInterface_Name: '${NVA_name}_1_nic_untrust'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet1_name, vnet1subnet_Names[1])
    privateIPAddress: NVA1untrustIP
    privateIPAllocationMethod: 'Static'
    addPublicIPAddress: true
    tagValues: {}
  }
  dependsOn: [
    NVAVnet
  ]
}

module NVA1MgmtNIC '../../../modules/Microsoft.Network/NetworkInterface.bicep' = {
  name: '${NVA_name}_1_nic_mgmt'
  params: {
    acceleratedNetworking: false
    networkInterface_Name: '${NVA_name}_1_nic_mgmt'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet1_name, vnet1subnet_Names[2])
    privateIPAllocationMethod: 'Dynamic'
    addPublicIPAddress: true
    tagValues: {}
  }
  dependsOn: [
    NVAVnet
  ]
}

module NVA1 '../../../modules/Microsoft.Compute/OPNSense/OpnSenseNVA.bicep' = {
  name: '${NVA_name}1'
  params: {
    NVAName: '${NVA_name}1'
    VMSize: VMSize
    untrustnic_objectid: NVA1UntrustNIC.outputs.networkInterface_ID
    trustnic_objectid: NVA1TrustNIC.outputs.networkInterface_ID
    mgmtnic_objectid: NVA1MgmtNIC.outputs.networkInterface_ID
    virtualMachine_AdminUsername: 'azureadmin'
    virtualMachine_AdminPassword: 'Password1234!'
    OPNScriptURI: OPNScriptURI
    ShellScriptName: ScriptName
    ShellScriptObj: {
      WALinuxVersion: WALinuxVersion
      OpnVersion: OPNVersion
      OpnScriptURI: script_location
      OpnType: 'TwoNics'
      TrustedSubnetName: vnet1subnet_Names[0]
    }
  }
  dependsOn: [
    NVAVnet
  ]
}

module WebServer '../../../modules/Microsoft.Compute/Ubuntu20/VirtualMachine.bicep' = {
  name: 'WebServer'
  params: {
    virtualMachine_Name: 'UbuntuWebServer'
    virtualMachine_Size: 'Standard_D2s_v4'
    networkInterface_Name: 'WebServer_NIC'
    subnet_ID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet2_name , vnet2subnet_Names[0])
    virtualMachine_AdminUsername: webserveradmin
    virtualMachine_AdminPassword: webserverpassword
    SSHKey: SSHKey
    acceleratedNetworking: false
    privateIPAddress: 'Dynamic'
    virtualMachine_ScriptFileLocation: script_location
    virtualMachine_ScriptFileName: script_name 
    commandToExecute: 'bash ${script_name}'
    tagValues: {}
  }
  dependsOn: [
    SpokeVnet
  ]
}

module VPNGateway '../../../modules/Microsoft.Network/VirtualNetworkGateway.bicep' = {
  name: 'VPNGateway'
  params: {
    virtualNetworkGateway_Name: 'VPNGateway'
    virtualNetworkGateway_SKU: 'VpnGw1'
    vpnGatewayGeneration: 'Generation1'
    virtualNetworkGateway_ASN: 65001
    virtualNetworkGateway_Subnet_ResourceID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet1_name, 'GatewaySubnet')
  }
  dependsOn: [
    NVAVnet
  ]
}

module LNG '../../../modules/Microsoft.Network/Connection_and_LocalNetworkGateway.bicep'= {
  name: 'LNG'
  params: {
    vpn_Destination_Name: OnPremName
    vpn_Destination_PublicIPAddress: OnPremPublicIP
    vpn_Destination_BGPIPAddress: OnPremBGPIP
    vpn_Destination_ASN: OnPremASN
    vpn_SharedKey: OnPremSharedKey
    virtualNetworkGateway_ID: VPNGateway.outputs.virtualNetworkGateway_ResourceID
  }
}
