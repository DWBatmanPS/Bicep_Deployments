param KeyVaultName   string = 'DanWheelerVaultStr'
param automation_ManagedIdentityName   string = 'DWAutomation-servicePrincipal'
param keyvaultmanagedidentity_name   string = 'DWKeyVaultManagedIdentity'

var DeploymentLocation = resourceGroup().location

resource automation_ManagedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: automation_ManagedIdentityName
  location: DeploymentLocation
  tags: {
  }
}


resource Keyvault_ManagedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: keyvaultmanagedidentity_name
  location: DeploymentLocation
  tags: {
  }
}

module keyvault '../../modules/Microsoft.Keyvault/keyvault_with_managedID.bicep' = {
  name: 'keyvault'
  params: {
    keyVaultName: KeyVaultName
    Keyvault_ManagedID: Keyvault_ManagedID.properties.principalId
    Automation_ManagedID: automation_ManagedID.properties.principalId
  }
}

module automation_account '../../modules/Microsoft.Automation/Automation_account.bicep' = {
  name: 'automation_account'
  params: {
    automationaccount: 'labdeployment-automation'
    DeploymentLocation: DeploymentLocation
    automation_managed_ID: automation_ManagedIdentityName
  }
}

module automation_contrib_role '../../modules/Microsoft.Authorization/subscription_contributor_role.bicep' = {
  name: 'automation_contrib_role'
  scope: subscription()
  params: {
    automation_managedID_principal: automation_ManagedID.properties.principalId
  }
}
