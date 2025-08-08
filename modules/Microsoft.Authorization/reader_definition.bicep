param managedidentity_name string
param randomstring string
param ManagedID object
param reader_role_definition string
param RG string

targetScope = 'resourceGroup'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: RG
}

resource Reader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(managedidentity_name, randomstring, 'reader_module')
  scope: resourceGroup
  properties: {
    principalId:  ManagedID.properties.principalId
    roleDefinitionId: reader_role_definition
    principalType: 'ServicePrincipal'
  }
}
