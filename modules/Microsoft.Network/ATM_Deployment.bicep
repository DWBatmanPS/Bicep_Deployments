param ATM_Name string = 'bicep-atm-profile'

param atmsubdomain string = 'bicep-atm-profile'

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

param externalEndpointNames array = [
  'Endpoint1'
  'Endpoint2'
  'Endpoint3'
  'Endpoint4'
]
param endpoint array = [
  'www.contoso.com'
  'www.fabrikam.com'
  'www.adventure-works.com'
  '1.1.1.1'
]

param weight array = [
  1
  1
  1
]

param customHostNeeded bool = false

var globallocation = 'global'
var port = probeProtocol == 'HTTP' ? 80 : probeProtocol == 'HTTPS' ? 443 : customPort

resource ATM 'Microsoft.Network/trafficmanagerprofiles@2022-04-01' = {
  name: ATM_Name
  location: globallocation
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: RoutingMethod
    dnsConfig: {
      relativeName: atmsubdomain
      ttl: 60
    }
    monitorConfig: {
      protocol: probeProtocol
      port: port
    }
  }
}

resource ExternalEndpoint 'Microsoft.Network/trafficmanagerprofiles/externalendpoints@2022-04-01' = [for (endpointName, i) in externalEndpointNames: {
  parent: ATM
  name: endpointName
  properties: {
    customHeaders: (customHostNeeded) ? [{
        name: 'Host'
        value: endpoint[i]
      } 
    ] : null
    target: endpoint[i]
    endpointStatus: 'Enabled'
    weight: weight[i]
  }
}]
