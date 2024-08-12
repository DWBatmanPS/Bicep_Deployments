param managedidentity_name string
param aks_oidc_issuer string
param federated_id_subject string

var DeploymentLocation = resourceGroup().location


resource ManagedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedidentity_name
  location: DeploymentLocation
}

resource ManagedIdFederation 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: '${managedidentity_name}-federation'
  parent: ManagedID
  properties: {
    audiences: [
      environment().suffixes.acrLoginServer
    ]
    issuer: aks_oidc_issuer
    subject: federated_id_subject
  }
}


output clientID string = ManagedID.properties.clientId
output PrincipalID string = ManagedID.properties.principalId
output ManagedID_Federation string = ManagedIdFederation.name
