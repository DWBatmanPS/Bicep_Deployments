param ATM_Name string = 'bicep-atm-profile'

param atmsubdomain string = 'bicep-atm-profile'

@allowed([
  'Priority'
  'Weighted'
  'Performance'
  'Geographic'
  'MultiValue'
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

var globallocation = 'global'
var port = probeProtocol == 'HTTP' ? 80 : probeProtocol == 'HTTPS' ? 443 : customPort
var maxreturn = RoutingMethod == 'MultiValue' ? 5 : null

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
    maxReturn: maxreturn
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
    }
  }
}

