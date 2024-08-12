using './main.bicep' /*Provide a path to a bicep template*/

  param KeyVaultName = 'DanWheelerVaultStr'
  param automation_ManagedIdentityName = 'DWAutomation-servicePrincipal'
  param keyvaultmanagedidentity_name = 'DWKeyVaultManagedIdentity'
