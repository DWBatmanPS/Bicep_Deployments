@description('Name of the Virtual Network')
param virtualNetwork_Name string

@description('''An Array of Custom DNS Server IP Addresses.  Azure Wireserver will be used if left as an empty array [].
Example:
[10.0.0.4, 10.0.0.5]
''')
param dnsServers array = []

@description('Name of the General Network Security Group')
var networkSecurityGroup_Default_Name = '${virtualNetwork_Name}_NSG_General'

@description('Name of the General Route Table')
var routeTable_Name = '${virtualNetwork_Name}_RT_General'

param virtualNetwork_AddressPrefix string

param tagValues object = {}

param subnet_Names array = [
  'General'
  'PrivateEndpoints'
  'PrivateLinkService'
  'ApplicationGatewaySubnet'
  'AGCSubnet'
  'AppServiceSubnet'
  'GatewaySubnet'
  'AzureFirewallSubnet'
  'AzureFirewallManagementSubnet'
  'AzureBastionSubnet'
  'PrivateResolver_Inbound'
  'PrivateResolver_Outbound'
  'AKSSubnet'
  'NVATrust'
  'NVAUntrust'
  'NVAMgmt'
]

param nvaIpAddress string = '10.0.0.4'
param deployudr bool = true
param customsourceaddresscidr string = '208.107.184.241/32'
param deploy_NatGateway bool = false
param publicipname string = 'Nat_Gateway_VIP'
param natgatewayname string = 'Nat_Gateway'
param UsecustomLocation bool = false
param customlocation string = 'eastus'

var location = (UsecustomLocation) ? customlocation: resourceGroup().location
var baseAddress = split(virtualNetwork_AddressPrefix, '/')[0]
var baseOctets = [int (split(baseAddress, '.')[0]), int(split(baseAddress, '.')[1]), int (split(baseAddress, '.')[2]), int (split(baseAddress, '.')[3])]

var subnetAddressPrefixes = [
  for (subnet_Name, index) in subnet_Names: {
    name: subnet_Name
    addressPrefix: '${baseOctets[0]}.${baseOctets[1]}.${baseOctets[2] + index}.0/24'
  }
]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: virtualNetwork_Name
  location: location
  properties: {
    dhcpOptions: {
      dnsServers: dnsServers
    }
    addressSpace: {
      addressPrefixes: [
        virtualNetwork_AddressPrefix
      ]
    }
    subnets: [
      for (subnet_Name, index) in subnet_Names: {
        name: subnetAddressPrefixes[index].name
        properties: {
          addressPrefix: subnetAddressPrefixes[index].addressPrefix
          networkSecurityGroup: (subnet_Name != 'AGCSubnet' && subnet_Name != 'AzureFirewallSubnet' && subnet_Name != 'AzureFirewallManagementSubnet' && subnet_Name != 'GatewaySubnet' && subnet_Name != 'AGSubnet' && subnet_Name != 'AzureBastionSubnet' && subnet_Name != 'AKSSubnet') ? (subnet_Name == 'AGSubnet') ?{
            id: networkSecurityGroup.id
          } : {
            id:networkSecurityGroup_ApplicationGateway.id
          }: null
          routeTable: (deployudr && (subnet_Name != 'AzureFirewallSubnet' && subnet_Name != 'AzureFirewallManagementSubnet' && subnet_Name != 'GatewaySubnet' && subnet_Name != 'AGCSubnet' && subnet_Name != 'AGSubnet' && subnet_Name != 'AzureBastionSubnet' && subnet_Name != 'NVATrust' && subnet_Name != 'NVAUntrust' && subnet_Name != 'NVAMgmt')) ? {
            id: routeTable.id
          } : null
          delegations: (subnet_Name == 'AGCSubnet') ? [
            {
              name: 'Microsoft.ServiceNetworking/trafficControllers'
              properties: {
                serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
              }
            }
          ] : null
          natGateway: (deploy_NatGateway && deployudr != true && (subnet_Name != 'AzureFirewallSubnet' && subnet_Name != 'AzureFirewallManagementSubnet' && subnet_Name != 'GatewaySubnet' && subnet_Name != 'AGCSubnet' && subnet_Name != 'AGSubnet' && subnet_Name != 'AzureBastionSubnet' && subnet_Name != 'NVATrust' && subnet_Name != 'NVAUntrust' && subnet_Name != 'NVAMgmt')) ? {
            id: natgateway.id
          } : null
        }
      }
    ]
  }
}

resource routeTable 'Microsoft.Network/routeTables@2023-02-01' = if (deployudr){
  name: routeTable_Name
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      { id: resourceId('Microsoft.Network/routeTables/routes', routeTable_Name, 'VirtualNetworkRoute')
        name: 'VirtualNetworkRoute'
        properties: {
          addressPrefix: virtualNetwork_AddressPrefix
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: nvaIpAddress
        }
      }
    ]
  }
  tags: tagValues
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: networkSecurityGroup_Default_Name
  location: location
  properties: {
    securityRules: [
      {
        id: resourceId('Microsoft.Network/networkSecurityGroups/securityRules', networkSecurityGroup_Default_Name, 'AllowCustomInbound')
        name: 'AllowCustomInbound'
        properties: {
          description: 'Allow Custom Inbound'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: customsourceaddresscidr
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          destinationPortRanges: [
            '22'
            '3389'
          ]
        }
      }
      {
        id: resourceId('Microsoft.Network/networkSecurityGroups/securityRules', networkSecurityGroup_Default_Name, 'AllowCustomInbound')
        name: 'AllowCustomhttphttpsInbound'
        properties: {
          description: 'Allow Custom HTTP and HTTPS Inbound'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: customsourceaddresscidr
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
      {
        id: resourceId('Microsoft.Network/networkSecurityGroups/securityRules', networkSecurityGroup_Default_Name, 'Allow443inbound')
        name: 'Allow443inbound'
        properties: {
          description: 'Allow 443 inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 102
          direction: 'Inbound'
          destinationPortRanges: [
            '443'
          ]
        }
      }
      {
        name: 'AllowGatewayManager'
        properties: {
          description: 'Allow GatewayManager'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1003
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        id: resourceId('Microsoft.Network/networkSecurityGroups/securityRules', networkSecurityGroup_Default_Name, 'AllowHttpInboundlocal')
        name: 'AllowHttpInboundlocal'
        properties: {
          description: 'Allow Http Inbound'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 1004
          direction: 'Inbound'
          destinationPortRanges: [
            '80'
          ]
        }
      }
    ]
  }
  tags: tagValues
}

resource networkSecurityGroup_ApplicationGateway 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: '${virtualNetwork_Name}_NSG_ApplicationGateway'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowGatewayManager'
        properties: {
          description: 'Allow GatewayManager'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          description: 'Allow HTTPS'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1001
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowHTTPlocal'
        properties: {
          description: 'Allow HTTP from local'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1002
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowHTTPfromCustom'
        properties: {
          description: 'Allow HTTP from custom'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: customsourceaddresscidr
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1003
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
  tags: tagValues
}

resource publicip 'Microsoft.Network/publicIPAddresses@2021-05-01' = if (deploy_NatGateway) {
  name: publicipname
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource natgateway 'Microsoft.Network/natGateways@2021-05-01' = if (deploy_NatGateway){
  name: natgatewayname
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicip.id
      }
    ]
  }
}

output virtualNetwork_Name string = virtualNetwork.name
output virtualNetwork_ID string = virtualNetwork.id
output virtualNetwork_AddressPrefix string = virtualNetwork.properties.addressSpace.addressPrefixes[0]
output subnets array = virtualNetwork.properties.subnets
output routeTable_Name string = routeTable.name
output routeTable_ID string = routeTable.id

output networkSecurityGroup_Name string = networkSecurityGroup.name
output networkSecurityGroup_ID string = networkSecurityGroup.id
