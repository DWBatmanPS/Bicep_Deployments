using './main.bicep' /*Provide a path to a bicep template*/

  param DeploymentLocation_param = 'centralus'
  param KeyVaultName_param = 'DanWheelerVaultStr'
  param automation_ManagedIdentityName_param = 'DWAutomation-servicePrincipal'
  param keyvaultmanagedidentity_name_param = 'DWKeyVaultManagedIdentity'
