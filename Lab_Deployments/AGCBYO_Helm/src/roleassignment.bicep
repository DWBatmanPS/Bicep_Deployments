param managedidentity_name string
param principalId string
param roleDefinitionId string

targetScope = 'resourceGroup'

resource Reader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedidentity_name, 'reader_module')
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    principalType: 'ServicePrincipal'
  }
}
