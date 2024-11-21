param keyVaultName string
param kvsecretuserrole string
param kvsecretofficerrole string
param location string = resourceGroup().location
param enabledForDeployment bool = false
param enabledForDiskEncryption bool = false
param enabledForTemplateDeployment bool = false
param tenantId string = subscription().tenantId
param skuName string = 'standard'
param rbacAuthorization bool = true
param Keyvault_ManagedID string
param Automation_ManagedID string

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    tenantId: tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 60
    enableRbacAuthorization: rbacAuthorization
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource keyvault_secretuser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(kvsecretuserrole)
  scope: kv
  properties: {
    principalId: Keyvault_ManagedID
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalType: 'ServicePrincipal'
  }
}

resource automation_user 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(kvsecretofficerrole)
  scope: kv
  properties: {
    principalId: Automation_ManagedID
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalType: 'ServicePrincipal'
  }
}

output keyVaultId string = kv.name
