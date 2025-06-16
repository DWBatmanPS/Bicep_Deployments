param vnet1_name string = 'NVAVnet'
param vnet2_name string = 'SpokeVnet'
param vnet3_name string = 'RemoteVnet'
param virtualNetwork1_AddressPrefix string = '10.0.0.0/16'
param virtualNetwork2_AddressPrefix string = '10.1.0.0/16'
param virtualNetwork3_AddressPrefix string = '192.168.0.0/16'
param vnet1subnet_Names array = [
  'NVATrust'
  'NVAUntrust'
  'RouteServerSubnet'
  'GatewaySubnet'
]
param vnet2subnet_Names array = [
  'PESubnet'
  'VMsubnet'
]
  param vnet3subnet_Names array = [
  'GatewaySubnet'
  'VMsubnet'
]
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
@secure()
param SharedKey string
@secure()
param SSHKey string
param OPNScriptURI string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-vm-opnsense-nva/scripts/'
param ScriptName string = 'opnsense.sh'
param OPNVersion string = '25.1'
param WALinuxVersion string = '2.12.0.4'
param customnsgblock array = []


module NVAVnet '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: 'NVAVnet'
  params: {
    virtualNetwork_Name: vnet1_name

    virtualNetwork_AddressPrefix: virtualNetwork1_AddressPrefix
    subnet_Names: vnet1subnet_Names
    deployudr: false
    customsourceaddresscidr: customcidr
    customnsgblock: customnsgblock
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

module RemoteVnet '../../../modules/Microsoft.Network/VirtualNetwork.bicep' = {
  name: 'RemoteVnet'
  params: {
    virtualNetwork_Name: vnet3_name
    virtualNetwork_AddressPrefix: virtualNetwork3_AddressPrefix
    subnet_Names: vnet3subnet_Names
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
    NVAip: NVA1trustIP
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

module NVA1 '../../../modules/Microsoft.Compute/OPNSense/OpnSenseNVA.bicep' = {
  name: '${NVA_name}1'
  params: {
    NVAName: '${NVA_name}1'
    VMSize: VMSize
    untrustnic_objectid: NVA1UntrustNIC.outputs.networkInterface_ID
    trustnic_objectid: NVA1TrustNIC.outputs.networkInterface_ID
    virtualMachine_AdminUsername: 'azureadmin'
    virtualMachine_AdminPassword: 'Password1234!'
    OPNScriptURI: OPNScriptURI
    ShellScriptName: ScriptName
    vnetname: vnet1_name
    ShellScriptObj: {
      WALinuxVersion: WALinuxVersion
      OpnVersion: OPNVersion
      OpnScriptURI: OPNScriptURI
      OpnType: 'TwoNics'
      TrustedSubnetName: vnet1subnet_Names[0]
      WindowsSubnetName: ''
      publicIPAddress: NVA1UntrustNIC.outputs.networkInterface_PublicIPAddress
      opnSenseSecondarytrustedNicIP: NVA1TrustNIC.outputs.networkInterface_PrivateIPAddress
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
    virtualNetworkGateway_ASN: 65515
    virtualNetworkGateway_Subnet_ResourceID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet1_name, 'GatewaySubnet')
    activeActive: true
  }
  dependsOn: [
    NVAVnet
  ]
}

module RemoteVPNGateway '../../../modules/Microsoft.Network/VirtualNetworkGateway.bicep' = {
  name: 'RemoteVPNGateway'
  params: {
    virtualNetworkGateway_Name: 'RemoteVPNGateway'
    virtualNetworkGateway_SKU: 'VpnGw1'
    vpnGatewayGeneration: 'Generation1'
    virtualNetworkGateway_ASN: 65530
    virtualNetworkGateway_Subnet_ResourceID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet3_name, 'GatewaySubnet')
    activeActive: true
  }
  dependsOn: [
    RemoteVnet
  ]
}

module Connection1 '../../../modules/Microsoft.Network/VPNConnection_two_azure_Gateways.bicep'= {
  name: 'Connection1'
  params: {
    virtualNetworkGateway_ID: VPNGateway.outputs.virtualNetworkGateway_ResourceID
    virtualNetworkGateway_ID2: RemoteVPNGateway.outputs.virtualNetworkGateway_ResourceID
    vpn_SharedKey: SharedKey
  }
}

module Connection2 '../../../modules/Microsoft.Network/VPNConnection_two_azure_Gateways.bicep'= {
  name: 'Connection2'
  params: {
    virtualNetworkGateway_ID: RemoteVPNGateway.outputs.virtualNetworkGateway_ResourceID
    virtualNetworkGateway_ID2: VPNGateway.outputs.virtualNetworkGateway_ResourceID
    vpn_SharedKey: SharedKey
  }
}

