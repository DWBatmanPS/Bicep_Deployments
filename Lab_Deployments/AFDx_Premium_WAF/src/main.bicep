

@description('The name of the SKU to use when creating the App Service plan.')
param appServicePlanSkuName string = 'B1'

@description('The number of worker instances of your App Service plan that should be provisioned.')
param appServicePlanCapacity int = 1

@description('The name of the SKU to use when creating the Front Door profile.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param frontDoorSkuName string = 'Premium_AzureFrontDoor'

param AFDWAF_Name string = 'DWAFDwafPremium'
param wafState string = 'Enabled'
param wafMode string = 'Prevention'
param inspectBody string = 'Enabled'
@allowed([
  '2.1'
  '3.2'
  '3.1'
  '3.0'
  '2.0'
])
param ruleSet string = '2.0'

@description('The location into which regionally scoped resources should be deployed. Note that Front Door is a global resource.')
var location  = resourceGroup().location

@description('The name of the App Service application to create. This must be globally unique.')
var appName  = 'DW-${uniqueString(resourceGroup().id)}'
@description('The name of the Front Door endpoint to create. This must be globally unique.')
var frontDoorEndpointName  = 'afd-${uniqueString(resourceGroup().id)}'
var appServicePlanName = 'DWAppService_Plan'

var frontDoorProfileName = 'DWAFDPREMProfile'
var frontDoorOriginGroupName = 'BicepOriginGroup'
var frontDoorOriginName = 'AppServiceOrigin'
var frontDoorRouteName = 'AppServiceRoute'

resource frontDoorProfile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: frontDoorProfileName
  location: 'global'
  sku: {
    name: frontDoorSkuName
  }
}

resource appServicePlan 'Microsoft.Web/serverFarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
    capacity: appServicePlanCapacity
  }
  kind: 'app'
}

resource app 'Microsoft.Web/sites@2020-06-01' = {
  name: appName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      detailedErrorLoggingEnabled: true
      httpLoggingEnabled: true
      requestTracingEnabled: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      ipSecurityRestrictions: [
        {
          tag: 'ServiceTag'
          ipAddress: 'AzureFrontDoor.Backend'
          action: 'Allow'
          priority: 100
          headers: {
            'x-azure-fdid': [
              frontDoorProfile.properties.frontDoorId
            ]
          }
          name: 'Allow traffic from Front Door'
        }
      ]
    }
  }
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: frontDoorEndpointName
  parent: frontDoorProfile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: frontDoorOriginGroupName
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'NotSet'
      probeProtocol: 'NotSet'
      probeIntervalInSeconds: 100
    }
  }
}

resource frontDoorOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: frontDoorOriginName
  parent: frontDoorOriginGroup
  properties: {
    hostName: app.properties.defaultHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: app.properties.defaultHostName
    priority: 1
    weight: 1000
  }
}

resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: frontDoorRouteName
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOrigin // This explicit dependency is required to ensure that the origin group is not empty when the route is created.
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
}


var rulesettype = ruleSet == '2.0' ? 'DRS' : 'OWASP'
var ruleSets = concat([
  {
    ruleSetType: rulesettype
    ruleSetVersion: ruleSet
    ruleSetAction: 'Block'
    exclusions: []
    ruleGroupOverrides: []
  }
])
resource AFDWAF 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2024-02-01' = {
  name: AFDWAF_Name
  location: 'global'
  properties: {
    customRules: {rules: []}
    policySettings: {
      requestBodyCheck: inspectBody
      enabledState: wafState
      mode: wafMode
    }
    managedRules: {
      managedRuleSets: ruleSets
    }
  }
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
}


output appServiceHostName string = app.properties.defaultHostName
output frontDoorEndpointHostName string = frontDoorEndpoint.properties.hostName
