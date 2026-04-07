targetScope = 'subscription'

param managedidentity_name string = 'albmanagedid'
param managedid_RG string
param nodeResourceGroup string

var reader_role = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource ManagedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedidentity_name
  scope: resourceGroup(managedid_RG)
}

resource reader_role_definition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: reader_role
}

module Reader './roleassignment.bicep' = {
  name: 'readerRoleAssignment'
  scope: resourceGroup(nodeResourceGroup)
  params: {
    managedidentity_name: managedidentity_name
    principalId: ManagedID.properties.principalId
    roleDefinitionId: reader_role_definition.id
  }
}
