using './main.bicep' /*Provide a path to a bicep template*/

  param policyname = 'azfwpolicy'
  param dnsenabled = true
  param azfwsku = 'Standard'
  param learnprivaterages = 'Enabled'
  param azfw = 'exampleazfw'
  param VnetName = 'default'
  param VnetPrefix = '10.0.0.0/16'
  param useForceTunneling = false
  param dnsServers = []
  param subnet_Names = [
    'AzureFirewallSubnet'
  ]
