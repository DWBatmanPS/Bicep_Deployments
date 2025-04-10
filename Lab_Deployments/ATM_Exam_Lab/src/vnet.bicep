@description('Name of the Virtual Network')
param virtualNetwork_Name string

@description('Name of the General Network Security Group')
var networkSecurityGroup_Default_Name = '${virtualNetwork_Name}_NSG_General'

param virtualNetwork_AddressPrefix string

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

param breakNSG bool = false

param tags object = {}

var ngsrules = (breakNSG) ?  [
  {
    id: resourceId('Microsoft.Network/networkSecurityGroups/securityRules', networkSecurityGroup_Default_Name, 'AllowCustomInbound')
    name: 'AllowCustomhttphttpsInbound'
    properties: {
      description: 'Allow Custom HTTP and HTTPS Inbound'
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: 'AzureFrontDoor.Backend'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 101
      direction: 'Inbound'
      destinationPortRanges: [
        '80'
      ]
    }
  }
] : [
  {
    id: resourceId('Microsoft.Network/networkSecurityGroups/securityRules', networkSecurityGroup_Default_Name, 'AllowCustomInbound')
    name: 'AllowCustomhttphttpsInbound'
    properties: {
      description: 'Allow Custom HTTP and HTTPS Inbound'
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: 'AzureTrafficManager'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 101
      direction: 'Inbound'
      destinationPortRanges: [
        '80'
      ]
    }
  }
]

var tagValues = tags

var location = resourceGroup().location
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
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
  tags: tagValues
  dependsOn: [
    networkSecurityGroup
  ]
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: networkSecurityGroup_Default_Name
  location: location
  properties: {
    securityRules: ngsrules
  }
  tags: tagValues
}


output virtualNetwork_Name string = virtualNetwork.name
output virtualNetwork_ID string = virtualNetwork.id
output virtualNetwork_AddressPrefix string = virtualNetwork.properties.addressSpace.addressPrefixes[0]
output subnets array = virtualNetwork.properties.subnets

output networkSecurityGroup_Name string = networkSecurityGroup.name
output networkSecurityGroup_ID string = networkSecurityGroup.id
