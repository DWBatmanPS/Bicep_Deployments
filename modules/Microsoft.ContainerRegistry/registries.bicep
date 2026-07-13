
@description('Name of the Azure Container Registry. Must be globally unique and alphanumeric.')
param acrName string = 'dwacr${uniqueString(resourceGroup().id)}'

@description('Azure Datacenter that the resource is deployed to')
param location string = resourceGroup().location

@description('SKU of the Azure Container Registry. Private Endpoints are only supported on the Premium SKU.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Enables the admin user (username/password) on the registry. Disabled by default in favour of Entra ID / managed identity auth.')
param adminUserEnabled bool = false

@description('Deploy a Private Endpoint, Private DNS Zone, DNS records and VNet link. Only takes effect when sku is Premium.')
param deployPrivateEndpoint bool = false

@description('Controls public network access to the registry. When deploying a Private Endpoint you typically set this to Disabled (Premium only).')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Name of the existing Virtual Network the Private Endpoint will be deployed into.')
param vnetName string = 'appgw_vnet'

@description('Name of the existing subnet (within vnetName) the Private Endpoint will be deployed into.')
param subnetName string = 'AGSubnet'

@description('Resource group of the existing Virtual Network. Defaults to the current resource group.')
param vnetResourceGroup string = resourceGroup().name

@description('Name of the Private Endpoint. Defaults to a name derived from the registry name.')
param privateEndpoint_Name string = '${acrName}-pe'

@description('Create a new Private DNS Zone. Set to false to reuse an existing zone (supply existingPrivateDnsZoneId).')
param createPrivateDnsZone bool = true

@description('Resource ID of an existing Private DNS Zone (privatelink.azurecr.io) to reuse. Required when createPrivateDnsZone is false and a Private Endpoint is deployed.')
param existingPrivateDnsZoneId string = ''

@description('Tags applied to the deployed resources.')
param tagValues object = {}

// ---------------------------------------------------------------------------
// Guards / derived values
// ---------------------------------------------------------------------------

@description('True only when a Premium registry has been requested with a Private Endpoint.')
var deployPrivateNetworking = deployPrivateEndpoint && sku == 'Premium'

@description('Private link group ID for a container registry.')
var acrGroupId = 'registry'

@description('Private DNS zone name for ACR. Uses the environment suffix so it resolves correctly in sovereign clouds.')
var privateDnsZoneName = 'privatelink${environment().suffixes.acrLoginServer}'

// ---------------------------------------------------------------------------
// Container Registry
// ---------------------------------------------------------------------------

resource ACR 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    // publicNetworkAccess can only be Disabled on Premium; coerce for lower SKUs to avoid a deployment error.
    publicNetworkAccess: sku == 'Premium' ? publicNetworkAccess : 'Enabled'
  }
  tags: tagValues
}

// ---------------------------------------------------------------------------
// Private networking (Premium only)
// ---------------------------------------------------------------------------

// Reference the existing VNet so we can link it to the Private DNS Zone.
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = if (deployPrivateNetworking) {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
}

// Reference the existing subnet the Private Endpoint attaches to.
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = if (deployPrivateNetworking) {
  parent: vnet
  name: subnetName
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (deployPrivateNetworking) {
  name: privateEndpoint_Name
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${privateEndpoint_Name}_to_${acrName}'
        properties: {
          privateLinkServiceId: ACR.id
          groupIds: [
            acrGroupId
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

// New Private DNS Zone (privatelink.azurecr.io).
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (deployPrivateNetworking && createPrivateDnsZone) {
  name: privateDnsZoneName
  location: 'global'
  tags: tagValues
}

// Link the VNet to the newly created zone so records resolve from within the network.
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (deployPrivateNetworking && createPrivateDnsZone) {
  parent: privateDnsZone
  name: '${acrName}-to-${vnetName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
  tags: tagValues
}

// The DNS Zone Group tells the Private Endpoint to auto-create/maintain A records for the
// registry FQDN AND every regional data endpoint (<registry>.<region>.data.privatelink.azurecr.io).
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (deployPrivateNetworking) {
  parent: privateEndpoint
  name: '${acrGroupId}ZoneGroup'
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

output acrName string = ACR.name
output acrLoginServer string = ACR.properties.loginServer
output acrFqdn string = ACR.properties.loginServer
output acrId string = ACR.id
output privateEndpointId string = deployPrivateNetworking ? privateEndpoint.id : ''
output privateDnsZoneId string = (deployPrivateNetworking && createPrivateDnsZone) ? privateDnsZone.id : existingPrivateDnsZoneId
