var randomguid1 = guid('bicep-app')

param RGName1 string = 'ATM-EUS'

param DeploymentLocation1 string = 'eastus'

param RGName2 string = 'ATM-WE'

param DeploymentLocation2 string = 'West Europe'

param ATM_Name string = 'bicep-atm-profile'
param RoutingMethod string = 'Performance'
param probeProtocol string = 'HTTPS'
//param customPort int = 8080

@minLength(2)
@maxLength(3)
param initials string = 'DW'

param desiredLength int = 8

var uniqueStr1 = uniqueString(RGName1, DeploymentLocation1)
var randomString1 = substring(uniqueStr1, 0, desiredLength)
var uniqueStr2 = uniqueString(RGName2, DeploymentLocation2)
var randomString2 = substring(uniqueStr2, 0, desiredLength)

var appserviceplan1 = '${randomguid1}-bicep-app'
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

module rg1_deployment '../../../modules/Microsoft.Resources/Resource_Group.bicep' = {
  name: 'Resource_Group'
  params: {
    RGName: RGName1
    DeploymentLocation: DeploymentLocation1
  }
}

module rg2_deployment '../../../modules/Microsoft.Resources/Resource_Group.bicep' = {
  name: 'Resource_Group2'
  params: {
    RGName: RGName2
    DeploymentLocation: DeploymentLocation2
  }
}

module atm '../../../modules/Microsoft.Network/ATM_Deployment.bicep' = {
  name: 'ATM_Deployment'
  scope: resourceGroup(RGName1)
  params: {
    ATM_Name:ATM_Name
    RoutingMethod: RoutingMethod
    probeProtocol: probeProtocol
    customHostNeeded: true
    //customPort: customPort
    externalEndpointNames: externalEndpointNames
    endpoint: endpoint
    weight: weight
  }
}

module appserviceplan1_deployment '../../../modules/Microsoft.Web/appserviceplan.bicep' = {
  name: appserviceplan1
  scope: resourceGroup(RGName1)
  params: {
    appServicePlan_Name: appserviceplan1
  }
}
module webapp1_deployment '../../../modules/Microsoft.Web/site_only.bicep' = {
  name: webapp1
  scope: resourceGroup(RGName1)
  params: {
    appName: webapp1
    appServicePlan: appserviceplan1_deployment.outputs.appServicePlanId
  }
}

module webapp2_deployment '../../../modules/Microsoft.Web/site_only.bicep' = {
  name: webapp2
  scope: resourceGroup(RGName1)
  params: {
    appName: webapp2
    appServicePlan: appserviceplan1_deployment.outputs.appServicePlanId
  }
}
