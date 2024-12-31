param managedidentity_name string
param Subnetname string = 'agcSubnet'
param vnetName string = 'vnet'
param randomstring string

@allowed([
  'subnet'
  'vnet'
  'RG'
])
param resourcetype string = 'subnet'

var netcontrib_role = '4d97b98b-1d4f-4787-a291-c67834d212e7'
//var RG = resourcetype == 'subnet' ? false : resourcetype == 'vnet' ? false : true
var isresource = resourcetype == 'subnet' ? true : resourcetype == 'vnet' ? true : false
var issubnet = resourcetype == 'subnet' ? true : false

resource ManagedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedidentity_name
}

resource netcontrib_role_deffinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: netcontrib_role
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01'  existing = if (isresource){
  name: vnetName
} 

resource Subnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = if (issubnet){
  name: Subnetname
  parent: virtualNetwork
}

/* resource vnet_networkcontrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (isresource) {
  name: guid(managedidentity_name, randomstring)
  scope: virtualNetwork
  properties: {
    principalId:  ManagedID.properties.principalId
    roleDefinitionId: netcontrib_role_deffinition.id
    principalType: 'ServicePrincipal'
  }
}  */

resource subnet_networkcontrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (issubnet) {
  name: guid(managedidentity_name, randomstring, 'net_module')
  scope: Subnet
  properties: {
    principalId:  ManagedID.properties.principalId
    roleDefinitionId: netcontrib_role_deffinition.id
    principalType: 'ServicePrincipal'
  }
} 

/* resource networkcontrib 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (RG) {
  name: guid(managedidentity_name, randomstring)
  scope: resourceGroup()
  properties: {
    principalId:  ManagedID.properties.principalId
    roleDefinitionId: netcontrib_role_deffinition.id
    principalType: 'ServicePrincipal'
  }
}  */
