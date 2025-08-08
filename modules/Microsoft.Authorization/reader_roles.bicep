param managedidentity_name string
param randomstring string
param managedid_RG string 
param RG string 


var reader_role = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

targetScope = 'resourceGroup'

resource ManagedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedidentity_name
  scope: resourceGroup(managedid_RG)
}

resource reader_role_definition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: reader_role
}

module Reader 'reader_definition.bicep' = {
  name: 'reader_role_auth'
  params: {
    managedidentity_name: managedidentity_name
    randomstring: randomstring
    ManagedID: ManagedID
    reader_role_definition: reader_role_definition.id
  }
}


