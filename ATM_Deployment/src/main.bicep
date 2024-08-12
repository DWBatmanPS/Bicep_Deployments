var randomguid1 = guid('bicep-app')
var randomguid2 = guid('bicep-app2')

param ATM_Name string = 'bicep-atm-profile'
param RoutingMethod string = 'Performance'
param probeProtocol string = 'HTTP'
//param customPort int = 8080
param externalEndpointNames array = [
  'Endpoint1'
  'Endpoint2'
]
/* param endpoint array = [
  'www.contoso.com'
  'www.fabrikam.com'
  'www.adventure-works.com'
] */

param weight array = [
  1
  1
]

var appserviceplan1 = '${randomguid1}-bicep-app'
var webapp1  = 'bicep-webapp1'
var appserviceplan2 = '${randomguid2}bicep-app2'
var webapp2 = 'bicep-webapp2'

var fqdn1 = '${webapp1}.azurewebsites.net'
var fqdn2 = '${webapp2}.azurewebsites.net'

var endpoint = concat([fqdn1], [fqdn2])

module atm '../../modules/Microsoft.Network/ATM_Deployment.bicep' = {
  name: 'ATM_Deployment'
  params: {
    ATM_Name:ATM_Name
    RoutingMethod: RoutingMethod
    probeProtocol: probeProtocol
    //customPort: customPort
    externalEndpointNames: externalEndpointNames
    endpoint: endpoint
    weight: weight
  }
}

module webapp1_deployment '../../modules/Microsoft.Web/site.bicep' = {
  name: webapp1
  params: {
    appServicePlan_Name: appserviceplan1
    site_Name: webapp1
  }
}

module webapp2_deployment '../../modules/Microsoft.Web/site.bicep' = {
  name: webapp2
  params: {
    appServicePlan_Name: appserviceplan2
    site_Name: webapp2
  }
}
