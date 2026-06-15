@description('Name of the App Service Plan')
param appServicePlan_Name string

param tagValues object = {}

var location = resourceGroup().location

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlan_Name
  location: location
  sku: {
    name: 'P0v3'
    tier: 'Premium0v3'
    size: 'P0v3'
    family: 'Pv3'
    capacity: 0
  }
  kind: 'app'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: true
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
  tags: tagValues
}

output appServicePlanId string = appServicePlan.id
