param managedidentity_name string
param randomstring string

var agc_role = 'fbc52c3f-28ad-4303-a892-8a056630b8f1'


resource ManagedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedidentity_name
}

resource agc_role_deffinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: agc_role
}

resource agcconfig_mgr 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(managedidentity_name, randomstring, 'agc_role')
  properties: {
    principalId:  ManagedID.properties.principalId
    roleDefinitionId: agc_role_deffinition.id
    principalType: 'ServicePrincipal'
  }
} 
