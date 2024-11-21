param frontDoorProfileName string
param frontDoorSkuName string
param frontDoorEndpointName string
param frontDoorOriginGroupName array
param loadBalancingSampleSize int = 4
param loadBalancingSuccessfulSamplesRequired int = 3
param frontdoorprobepath string = '/'
param frontdoorProbeInterval int = 100
param frontdoorProbeRequestType string = 'NotSet'
param frontfoorProbeProtocol string = 'NotSet'
param frontDoorOriginName array
param frontdoorOriginhostName string
param frontdoorOriginHostHeader string
param customfrontdoorhttpport int = 0
param customfrontdoorhttpsport int = 0
param frontdoororiginpriority int = 1
param frontdoororiginweight int = 1000
param frontDoorRouteNames array
param frontdoorsupportedprotocols array = [
  'Http'
  'Https'
]
param frontdoorPathsToMatch array = [
  '/*'
]
param frontDoorForwardingProtocol string = 'HttpsOnly'
param linkToDefaultDomain string = 'true'
param httpsRedirect string = 'true'

var frontdoorhttpport = (customfrontdoorhttpport == 0) ? 80 : customfrontdoorhttpport
var frontdoorhttpsport = (customfrontdoorhttpsport == 0) ? 443 : customfrontdoorhttpsport


resource frontDoorProfile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: frontDoorProfileName
  location: 'global'
  sku: {
    name: frontDoorSkuName
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

resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = [for (originGroup, index) in frontDoorOriginGroupName: {
  name: originGroup[index]
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: loadBalancingSampleSize
      successfulSamplesRequired: loadBalancingSuccessfulSamplesRequired
    }
    healthProbeSettings: {
      probePath: frontdoorprobepath
      probeRequestType: frontdoorProbeRequestType
      probeProtocol: frontfoorProbeProtocol
      probeIntervalInSeconds: frontdoorProbeInterval
    }
  }
}]

resource frontDoorOrigins 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = [for (originName, index) in frontDoorOriginName: {
  name: originName[index]
  parent: frontDoorOriginGroup[index % length(frontDoorOriginGroupName)]
  properties: {
    hostName: frontdoorOriginhostName
    httpPort: frontdoorhttpport
    httpsPort: frontdoorhttpsport
    originHostHeader: frontdoorOriginHostHeader
    priority: frontdoororiginpriority
    weight: frontdoororiginweight
  }
}]

resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = [for (frontDoorRouteName, index) in frontDoorRouteNames: {
  name: frontDoorRouteName
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOrigins // This explicit dependency is required to ensure that the origin group is not empty when the route is created.
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroup[index % length(frontDoorOriginGroupName)].id
    }
    supportedProtocols: frontdoorsupportedprotocols
    patternsToMatch: frontdoorPathsToMatch
    forwardingProtocol: frontDoorForwardingProtocol
    linkToDefaultDomain: linkToDefaultDomain
    httpsRedirect: httpsRedirect
  }
}]


output frontDoorProfileId string = frontDoorProfile.id
