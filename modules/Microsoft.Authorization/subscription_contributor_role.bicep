param automation_managedID_principal string = '00000000-0000-0000-0000-000000000000'

targetScope = 'subscription'

resource automation_contrib_role 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('dw1-automation-contrib-role')
  properties: {
    principalId: automation_managedID_principal
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor role    principalType: 'ServicePrincipal'
    principalType: 'ServicePrincipal'
  }
}
