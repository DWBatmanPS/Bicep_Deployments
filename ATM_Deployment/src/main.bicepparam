using './main.bicep' /*Provide a path to a bicep template*/

  param RGName1 = 'ATM-EUS'
  param DeploymentLocation1 = 'eastus'
  param RGName2 = 'ATM-WE'
  param DeploymentLocation2 = 'West Europe'
  param ATM_Name = 'bicep-atm-profile'
  param RoutingMethod = 'Performance'
  param probeProtocol = 'HTTPS'
  //param customPort = 8080
  param initials = 'DW'
  param desiredLength = 8
