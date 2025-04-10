param ATM_Name string = 'bicep-atm-profile'

param ATMchild_Name string = 'bicep-atm-child-profile'

@allowed([
  'Priority'
  'Weighted'
  'Performance'
  'Geographic'
  'Multivalue'
  'Subnet'
])
param RoutingMethod string = 'Performance'

@allowed([
  'HTTP'
  'HTTPS'
  'TCP'
])
param probeProtocol string = 'HTTP'

param customPort int = 8080

param endpoint1 string = '1.1.1.1'
param endpoint2 string = '1.1.1.1'
param endpoint3 string = '1.1.1.1'
param currentTime string = utcNow()
param tags object = {}

var globallocation = 'global'
var port = probeProtocol == 'HTTP' ? 80 : probeProtocol == 'HTTPS' ? 443 : customPort
var path = probeProtocol == 'HTTP' ? '/' : probeProtocol == 'HTTPS' ? '/' : null
var randomSuffix1long = uniqueString(resourceGroup().id, ATM_Name, currentTime)
var randomSuffix2long = uniqueString(resourceGroup().id, ATMchild_Name, currentTime)
var randomSuffix1 = substring(randomSuffix1long, 0, 12)
var randomSuffix2 = substring(randomSuffix2long, 0, 12)
var ATM1FQDNGenstring = randomSuffix1
var ATM2FQDNGenstring = randomSuffix2

var tagValues = tags

resource ATM 'Microsoft.Network/trafficmanagerprofiles@2022-04-01' = {
  name: ATM_Name
  location: globallocation
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: RoutingMethod
    dnsConfig: {
      relativeName: ATM1FQDNGenstring
      ttl: 60
    }
    monitorConfig: {
      protocol: probeProtocol
      port: port
      path: path
    }
  }
  tags: tagValues
}

resource ChildATM 'Microsoft.Network/trafficmanagerprofiles@2022-04-01' = {
  name: ATMchild_Name
  location: globallocation
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: RoutingMethod
    dnsConfig: {
      relativeName: ATM2FQDNGenstring 
      ttl: 60
    }
    monitorConfig: {
      protocol: probeProtocol
      port: port
      path: path
    }
  }
  tags: tagValues
}

resource ExternalEndpoint1 'Microsoft.Network/trafficmanagerprofiles/externalendpoints@2022-04-01' = {
  parent: ATM
  name: 'Endpoint1'
  properties: {
    target:endpoint1
    endpointStatus: 'Enabled'
    geoMapping: [
      'CA'
    ]
  }
}

resource nesting1 'Microsoft.Network/trafficmanagerprofiles/NestedEndpoints@2022-04-01' = {
  parent: ATM
  name: 'NestedEndpoint1'
  properties: {
    targetResourceId: ChildATM.id
    endpointStatus: 'Enabled'
    geoMapping: [
    'GEO-EU'
    ]
  }
}

resource ChildExternalEndpoint1 'Microsoft.Network/trafficmanagerprofiles/externalendpoints@2022-04-01' = {
  parent: ChildATM
  name: 'Endpoint1'
  properties: {
    target:endpoint2
    endpointStatus: 'Enabled'
    geoMapping: [
      'DE'
    ]
  }
}

resource ChildExternalEndpoint2 'Microsoft.Network/trafficmanagerprofiles/externalendpoints@2022-04-01' = {
  parent: ChildATM
  name: 'Endpoint3'
  properties: {
    target:endpoint3
    endpointStatus: 'Enabled'
    geoMapping: [
      'GEO-EU'
    ]
  }
}
