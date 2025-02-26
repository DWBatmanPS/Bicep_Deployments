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
param Automation_ManagedID string = ''
param deployautomation bool = false
param managedidentity_name string

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

module keyvaultauthorization '../Microsoft.Authorization/secret_user.bicep' = {
  name: 'keyvaultauth'
  params: {
    keyVaultName: keyVaultName
    kvsecretuserrole: kvsecretuserrole
    managedidentity_name: managedidentity_name
  }
  dependsOn: [
    kv
  ]
}

resource automation_user 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (deployautomation) {
  name: guid(kvsecretofficerrole)
  scope: kv
  properties: {
    principalId: Automation_ManagedID
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalType: 'ServicePrincipal'
  }
}

output keyVaultId string = kv.name
