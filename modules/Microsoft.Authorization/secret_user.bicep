param keyVaultName string
param kvsecretuserrole string
param managedidentity_name string

var secretreaderrole = '4633458b-17de-408a-b874-0445c86b69e6'

resource secretreader_role_deffinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: secretreaderrole
}

resource ManagedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedidentity_name
  
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing =  {
  name: keyVaultName
}

resource keyvault_secretuser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(kvsecretuserrole)
  scope: kv
  properties: {
    principalId: ManagedID.properties.principalId
    roleDefinitionId: secretreader_role_deffinition.id
    principalType: 'ServicePrincipal'
  }
}
