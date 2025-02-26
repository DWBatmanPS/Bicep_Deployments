param managedidentity_name string
var DeploymentLocation = resourceGroup().location


resource ManagedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedidentity_name
  location: DeploymentLocation
}

output clientID string = ManagedID.properties.clientId
output PrincipalID string = ManagedID.properties.principalId
output ManagedID_Name string = ManagedID.name
