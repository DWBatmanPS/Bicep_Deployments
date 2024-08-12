// Params
param AGCname string = 'AGCName'
param FrontendName string = 'Frontend'
param AssociationName string = 'Association'
param VnetName string = 'vnet'
param subnetNames array = []
param resourcetags object = {}

// Variables
var DeploymentLocation = resourceGroup().location
var SubnetIDs = [for subnetName in subnetNames: resourceId('Microsoft.Network/virtualNetworks/subnets', VnetName, subnetName)]

resource applicationGatewayForContainers 'Microsoft.ServiceNetworking/trafficControllers@2023-11-01' = {
  name: AGCname
  location: DeploymentLocation
  tags:resourcetags
}

resource agc_frontend 'Microsoft.ServiceNetworking/trafficControllers/frontends@2023-11-01' = {
  parent: applicationGatewayForContainers
  location: DeploymentLocation
  name: FrontendName
  properties: {}
}

resource agc_subnet_association 'Microsoft.ServiceNetworking/trafficControllers/associations@2023-11-01' = [for (subnetName, i) in subnetNames: {
  parent: applicationGatewayForContainers
  location: DeploymentLocation
  name: '${AssociationName}-${subnetNames[i]}'
  properties: {
    associationType: 'subnets'
    subnet: {
      id: SubnetIDs[i]
    }
  }
}]

output AGC_ID string = applicationGatewayForContainers.id
output AGC_Frontend_ID string = agc_frontend.properties.fqdn
