param serviceprincipal string

param appgwname string
param randomstring string
param randomstring2 string

var reader_role = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var contrib_roleid = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource reader_role_deffinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: reader_role
}

resource contrib_role 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: contrib_roleid
}

resource appgw 'Microsoft.Network/applicationGateways@2024-05-01' existing = {
  name: appgwname
}

resource ManagedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: serviceprincipal
}

resource appgwcontrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(serviceprincipal, randomstring, contrib_roleid)
  scope: appgw
  properties: {
    principalId:  ManagedID.properties.principalId
    roleDefinitionId: contrib_role.id
    principalType: 'ServicePrincipal'
  }
}

resource agic_reader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(serviceprincipal, randomstring2, reader_role)
  properties: {
    principalId:  ManagedID.properties.principalId
    roleDefinitionId: reader_role_deffinition.id
    principalType: 'ServicePrincipal'
  }
}
