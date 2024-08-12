using './main.bicep' /*Provide a path to a bicep template*/

  param appServicePlan = 'dwAppserviceplan'
  param certname = 'danwheeler-rocks-wildcard' 
  param keyvault_managed_ID= 'DWKeyVaultManagedIdentity'
  param dnsServers = []
  param subnet_Names = [
    'AGSubnet'
  ]
  param virtualNetworkPrefix = '10.0.0.0/16'
  param virtualNetworkName = 'webappappgw_vnet'
  param publicIPAddressName = 'webappappgw_vip'
  param applicationGateWayName = 'dwwebapp-appgw'
  param keyVaultName = 'DanWheelerVaultStr'
