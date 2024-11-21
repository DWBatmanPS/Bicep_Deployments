param RGName string

param DeploymentLocation string = 'eastus'

targetScope = 'subscription'

resource Example_RG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: RGName
  location: DeploymentLocation
}
