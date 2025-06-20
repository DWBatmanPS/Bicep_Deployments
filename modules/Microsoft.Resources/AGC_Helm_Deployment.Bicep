metadata name = 'Helm Install command'
metadata description = 'An Azure CLI Deployment Script that allows you to deploy a helm chart on to a Kubernetes cluster.'
metadata owner = 'Pixel-Robots'

@description('The name of the Azure Kubernetes Service')
param aksName string

@description('How the deployment script should be forced to execute')
param forceUpdateTag  string = utcNow()

@description('An array of Azure RoleIds that are required for the DeploymentScript resource')
param rbacRolesNeeded array = [
  'b24988ac-6180-42a0-ab88-20f7382dd24c' //Contributor
  '7f6c6a51-bcf8-42ba-9220-52d62157d7db' //Azure Kubernetes Service RBAC Reader
  'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b' //Azure Kubernetes Service RBAC Cluster Admin
]

@description('Create "new" or use "existing" Managed Identity. Default: new')
@allowed([ 'new', 'existing' ])
param newOrExistingManagedIdentity string = 'new'

@description('For an existing Managed Identity, the Subscription Id it is located in')
param existingManagedIdentitySubId string = subscription().subscriptionId

@description('For an existing Managed Identity, the Resource Group it is located in')
param existingManagedIdentityResourceGroupName string = resourceGroup().name

@allowed([ 'OnSuccess', 'OnExpiration', 'Always' ])
@description('When the script resource is cleaned up')
param cleanupPreference string = 'OnSuccess'

@description('Set to true when deploying template across tenants') 
param isCrossTenant bool = false

@description('A delay before the script import operation starts. Primarily to allow Azure AAD Role Assignments to propagate')
param initialScriptDelay string = '120s'

param DeployName string = 'agc-controller'

param AGCVersion string = '1.6.7'

param ControllerNamespace string = 'azure-alb-system'

param AGCClientID string

var location = resourceGroup().location
var useExistingManagedIdentity = newOrExistingManagedIdentity == 'existing'
var managedIdentityName = 'id-AksRunCommandProxy-${location}'

resource aks 'Microsoft.ContainerService/managedClusters@2022-11-01' existing = {
  name: aksName
}

resource newDepScriptId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (!useExistingManagedIdentity) {
  name: managedIdentityName
  location: location
}

resource existingDepScriptId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (useExistingManagedIdentity) {
  name: managedIdentityName
  scope: resourceGroup(existingManagedIdentitySubId, existingManagedIdentityResourceGroupName)
}

var delegatedManagedIdentityResourceId = useExistingManagedIdentity ? existingDepScriptId.id : newDepScriptId.id

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleDefId in rbacRolesNeeded: {
  name: guid(aks.id, roleDefId, useExistingManagedIdentity ? existingDepScriptId.id : newDepScriptId.id)
  scope: aks
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefId)
    principalId: useExistingManagedIdentity ? existingDepScriptId.properties.principalId : newDepScriptId.properties.principalId
    principalType: 'ServicePrincipal'
    delegatedManagedIdentityResourceId: isCrossTenant ? delegatedManagedIdentityResourceId : null
  }
}]

resource runAksCommand 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'AKS-Run-${aks.name}-${deployment().name}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${useExistingManagedIdentity ? existingDepScriptId.id : newDepScriptId.id}': {}
    }
  }
  kind: 'AzureCLI'
  dependsOn: [
    rbac
  ]
  properties: {
    forceUpdateTag: forceUpdateTag
    azCliVersion: '2.57.0'
    timeout: 'PT10M'
    retentionInterval: 'P1D'
    environmentVariables: [
      { name: 'RG', value: resourceGroup().name }
      { name: 'aksName', value: aksName }
      { name: 'initialDelay', value: initialScriptDelay}
      { name: 'DeployName', value: DeployName}
      { name: 'AGCVersion', value: AGCVersion} // Version of AGIC to deploy
      { name: 'CONTROLLER_NAMESPACE', value: ControllerNamespace}
      { name: 'ALBClientID', value: AGCClientID}
    ]
    scriptContent: loadTextContent('../../scripts/agc-aks-run-command-file.sh')
    cleanupPreference: cleanupPreference
  }
}

@description('Array of command output from each Deployment Script AKS run command')
output commandOutput object ={
  Name: runAksCommand.name
  CommandOutput: runAksCommand.properties.outputs
}
