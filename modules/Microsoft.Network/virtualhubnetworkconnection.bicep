param virtualHub_Name string
param virtualNetwork_Name string
param virtualNetwork_ID string
param virtualHub_RouteTable_Default_ID string

resource virtualHub 'Microsoft.Network/virtualHubs@2024-05-01' existing = {
  name: virtualHub_Name
}

resource vhubconnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2024-05-01' = {
  parent: virtualHub
  name: '${virtualHub_Name}to${virtualNetwork_Name}'
  properties: {
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    remoteVirtualNetwork: {
      id: virtualNetwork_ID
    }
    routingConfiguration: {
      associatedRouteTable: {
        id: virtualHub_RouteTable_Default_ID
      }
    }
  }
}
