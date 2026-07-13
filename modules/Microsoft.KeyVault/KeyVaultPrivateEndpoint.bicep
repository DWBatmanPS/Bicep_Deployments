@description('Name of the existing Key Vault that the Private Endpoint will connect to.')
param keyVaultName string

@description('Name of the Private Endpoint.')
param privateEndpointName string = '${keyVaultName}-pe'

@description('Azure Datacenter that the Private Endpoint / DNS resources are deployed to.')
param location string = resourceGroup().location

@description('Name of the existing Virtual Network the Private Endpoint will be deployed into.')
param vnetName string

@description('Name of the existing subnet (within vnetName) the Private Endpoint will be deployed into.')
param subnetName string

@description('Resource group of the existing Virtual Network / subnet. Defaults to the current resource group.')
param vnetResourceGroup string = resourceGroup().name

@description('Resource group where the target Key Vault lives.')
param kvResourceGroupName string = resourceGroup().name

@description('Subscription ID where the target Key Vault lives. Defaults to the current subscription.')
param remoteSubscriptionId string = subscription().subscriptionId

@description('Create a new Private DNS Zone. Set to false to reuse an existing zone (supply existingPrivateDnsZoneId).')
param createPrivateDnsZone bool = true

@description('Resource ID of an existing Private DNS Zone (privatelink.vaultcore.azure.net) to reuse. Required when createPrivateDnsZone is false.')
param existingPrivateDnsZoneId string = ''

@description('Tags applied to the deployed resources.')
param tagValues object = {}

// ---------------------------------------------------------------------------
// Derived values
// ---------------------------------------------------------------------------

@description('Private link group ID for a Key Vault.')
var keyVaultGroupId = 'vault'

// GOTCHA: The Key Vault public FQDN is <vault>.vault.azure.net, but the private
// link DNS zone is privatelink.VAULTCORE.azure.net (not vault.azure.net).
// The replace() keeps this correct in sovereign clouds where the suffix differs.
var privateDnsZoneName = 'privatelink${replace(environment().suffixes.keyvaultDns, '.vault.', '.vaultcore.')}'

// ---------------------------------------------------------------------------
// Existing resource references
// ---------------------------------------------------------------------------

// The Key Vault may live in a different subscription / resource group.
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup(remoteSubscriptionId, kvResourceGroupName)
}

// VNet the endpoint attaches to (and the DNS zone links to).
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: vnet
  name: subnetName
}

// ---------------------------------------------------------------------------
// Private Endpoint + DNS
// ---------------------------------------------------------------------------

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}_to_${keyVaultName}'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            keyVaultGroupId
          ]
        }
      }
    ]
    subnet: {
      id: subnet.id
    }
  }
  tags: tagValues
}

// New Private DNS Zone (privatelink.vaultcore.azure.net).
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (createPrivateDnsZone) {
  name: privateDnsZoneName
  location: 'global'
  tags: tagValues
}

// Link the VNet to the newly created zone so records resolve from within the network.
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (createPrivateDnsZone) {
  parent: privateDnsZone
  name: '${keyVaultName}-to-${vnetName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
  tags: tagValues
}

// The DNS Zone Group tells the Private Endpoint to auto-create/maintain the A record.
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: '${keyVaultGroupId}ZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: createPrivateDnsZone ? privateDnsZone.id : existingPrivateDnsZoneId
        }
      }
    ]
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output privateEndpointId string = privateEndpoint.id
output privateEndpointName string = privateEndpoint.name
output privateDnsZoneId string = createPrivateDnsZone ? privateDnsZone.id : existingPrivateDnsZoneId
output keyVaultId string = keyVault.id
