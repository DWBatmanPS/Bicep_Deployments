param RGName string = 'ANP-RG'

param DeploymentLocation string = 'eastus'

targetScope = 'subscription'

resource AGC_RG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: RGName
  location: DeploymentLocation
}
