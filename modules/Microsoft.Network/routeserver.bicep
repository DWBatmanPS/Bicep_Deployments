param RouteServerName string = 'RouteServer'
param location string = resourceGroup().location
param virtualNetwork_Name string
param NVA_ASN int = 65001
param NVAip string = '10.0.0.1'

resource Vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: virtualNetwork_Name
}

resource Subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: 'RouteServerSubnet'
  parent: Vnet
}

resource RouteServerPublicIP 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: '${RouteServerName}_VIP'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource RouteServer 'Microsoft.Network/VirtualHubs@2024-05-01' = {
  location: location
  name: RouteServerName
  properties: {
    sku: 'Standard'
  }
}

resource RouteServerIPConfig 'Microsoft.Network/virtualHubs/ipConfigurations@2024-05-01' = {
  parent: RouteServer
  name: '${RouteServerName}_ipconfig1'
  properties: {
    publicIPAddress: {
      id: RouteServerPublicIP.id
    }
    subnet: {
      id: Subnet.id
    }
  }
}

resource RouteServerBGPConnection 'Microsoft.Network/virtualHubs/bgpConnections@2024-05-01' = {
  parent: RouteServer
  name: '${RouteServerName}_bgpConnection'
  properties: {
    peerAsn: NVA_ASN
    peerIp: NVAip
  }
  dependsOn: [
    RouteServerIPConfig
  ]
}
