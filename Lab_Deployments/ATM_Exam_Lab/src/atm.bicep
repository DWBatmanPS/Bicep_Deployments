param ATM_Name string = 'bicep-atm-profile'

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

param endpoint array = [
  'www.contoso.com'
  'www.fabrikam.com'
  'www.adventure-works.com'
  '1.1.1.1'
]

param currentTime string = utcNow()
param tags object = {}

var randomSuffix1long = uniqueString(resourceGroup().id, currentTime)
var randomSuffix1 = substring(randomSuffix1long, 0, 12)
var ATM1FQDNGenstring = randomSuffix1

var globallocation = 'global'
var port = probeProtocol == 'HTTP' ? 80 : probeProtocol == 'HTTPS' ? 443 : customPort
var path = probeProtocol == 'HTTP' ? '/' : probeProtocol == 'HTTPS' ? '/' : null

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

resource ExternalEndpoint1 'Microsoft.Network/trafficmanagerprofiles/externalendpoints@2022-04-01' = {
  parent: ATM
  name: 'Endpoint1'
  properties: {
    target: endpoint[0]
    endpointStatus: 'Enabled'
    endpointLocation: 'East US'
  }
}

resource ExternalEndpoint2 'Microsoft.Network/trafficmanagerprofiles/externalendpoints@2022-04-01' = {
  parent: ATM
  name: 'Endpoint2'
  properties: {
    target: endpoint[1]
    endpointStatus: 'Enabled'
    endpointLocation: 'West Europe'
  }
}
