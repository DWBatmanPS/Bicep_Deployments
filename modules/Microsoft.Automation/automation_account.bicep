param automationaccount string = 'labdeployment-automation'
param DeploymentLocation string = 'centralus'
param ID_Type string = 'UserAssigned'
param automation_managed_ID string

//var automation_managed_ID_PrincipalID = automation_managed_ID.properties.principalId
//var automation_managed_ID_ClientID = automation_managed_ID.properties.clientId



resource deploymentautomationaccount 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: automationaccount
  location: DeploymentLocation

  identity: {
    type: ID_Type
    userAssignedIdentities: {
      '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/',automation_managed_ID)}': {}
    }
  }
  properties: {
    publicNetworkAccess: true
    sku: {
      name: 'Free'
    }
  }
}
