using './main.bicep' /*Provide a path to a bicep template*/


param certname = 'danwheeler-rocks-wildcard' 

param keyvault_managed_ID = 'DWKeyVaultManagedIdentity'

param subnet_Names = [
  'AppGateway'
  'AzureFirewallSubnet'
  'backendSubnet'
]

param virtualNetworkPrefix = '10.0.0.0/16'

param virtualNetworkName = 'azfwforcetunnel'
param publicIPAddressName = 'zerotrustappgw-ip'
param applicationGateWayName = 'dwwebapp-appgw'


param keyVaultName = 'DanWheelerVaultStr'
@description('The name of the App Service application to create. This must be globally unique.')

param policyname = 'azfwpolicy'
param dnsenabled = true
param azfwsku = 'Premium'
param learnprivaterages = 'Enabled'
param azfw = 'exampleazfw'
param useForceTunneling = false
param homeip = '208.107.184.241/32'
param deployudr = true
param azfwinternalip = '10.0.1.4'
