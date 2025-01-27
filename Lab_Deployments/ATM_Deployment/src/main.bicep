param RGName1 string = 'ATM-EUS'

param DeploymentLocation1 string = 'eastus'

param RGName2 string = 'ATM-WE'

param RGName3 string = 'ATM-CUS'

param DeploymentLocation2 string = 'West Europe'

param DeploymentLocation3 string = 'Central US'

param ATM_Name string = 'bicep-atm-profile'
param atmsubdomain string = 'bicep-atm-profile'
param RoutingMethod string = 'Performance'
param probeProtocol string = 'TCP'
param customPort int = 443

@minLength(2)
@maxLength(3)
param initials string = 'DW'

param desiredLength int = 8

var appserviceplanName = guid(ATM_Name)
var uniqueStr1 = uniqueString(RGName1, DeploymentLocation1)
var randomString1 = substring(uniqueStr1, 0, desiredLength)
var uniqueStr2 = uniqueString(RGName2, DeploymentLocation2)
var randomString2 = substring(uniqueStr2, 0, desiredLength)

var webapp1  = '${initials}-${randomString1}'
var webapp2 = '${initials}-${randomString2}'

var fqdn1 = '${webapp1}.azurewebsites.net'
var fqdn2 = '${webapp2}.azurewebsites.net'

var endpoint = concat([fqdn1], [fqdn2])

var arrayLength = length(endpoint)

var arrayEntries = [for i in range(0, arrayLength) : {
  name: 'Weight${i}'
  value: 1
}]

var weight = [for entry in arrayEntries: entry.value]

var endpointnamearray = [for i in range(0, arrayLength) : {
  name: 'Endpoint${i}'
  value: 'Endpoint${i}'
}]

var externalEndpointNames = [for entry in endpointnamearray: entry.value]
targetScope = 'subscription'

resource rg1_deployment 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: RGName1
  location: DeploymentLocation1
}

resource rg2_deployment'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: RGName2
  location: DeploymentLocation2
}

resource rg3_deployment 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: RGName3
  location: DeploymentLocation3
}

module atm '../../../modules/Microsoft.Network/ATM_Deployment.bicep' = {
  name: 'ATM_Deployment'
  scope: rg3_deployment
  params: {
    ATM_Name:ATM_Name
    atmsubdomain: atmsubdomain
    RoutingMethod: RoutingMethod
    probeProtocol: probeProtocol
    customHostNeeded: true
    customPort: customPort
    externalEndpointNames: externalEndpointNames
    endpoint: endpoint
    weight: weight
  }
}

module appserviceplan1_deployment '../../../modules/Microsoft.Web/appserviceplan.bicep' = {
  name: 'DWAppService-bicep-app'
  scope: rg1_deployment
  params: {
    appServicePlan_Name: '${ATM_Name}-bicep-app'
  }
}
module webapp1_deployment '../../../modules/Microsoft.Web/site_only.bicep' = {
  name: webapp1
  scope: rg1_deployment
  params: {
    appName: webapp1
    appServicePlan: appserviceplan1_deployment.outputs.appServicePlanId
  }
}

module webapp2_deployment '../../../modules/Microsoft.Web/site_only.bicep' = {
  name: webapp2
  scope: rg1_deployment
  params: {
    appName: webapp2
    appServicePlan: appserviceplan1_deployment.outputs.appServicePlanId
  }
}
