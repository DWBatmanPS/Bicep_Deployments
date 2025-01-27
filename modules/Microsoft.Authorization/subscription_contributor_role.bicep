param automation_managedID_principal string = '00000000-0000-0000-0000-000000000000'

targetScope = 'subscription'

resource contrib_role 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource automation_contrib_role 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(automation_managedID_principal, 'dw1-automation-contrib-role')
  properties: {
    principalId: automation_managedID_principal
    roleDefinitionId: contrib_role.id
    principalType: 'ServicePrincipal'
  }
}
